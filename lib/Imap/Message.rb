# Imap/Message.rb
# Imap::Message

# Usage:
# 1. Imap::Message.search(imap_client, {from: 'noreply@example.com'})
# 2. Imap::Message.for(imap_client, imap_client.imap.search(['ALL']))
# 3. Imap::Message.new(message_id, imap_client)
# 4. Imap::Message.new(message_id, imap_client).body
# 5. Imap::Message.new(message_id, imap_client).urls
# 6. Imap::Message.new(message_id, imap_client).mark_as_read
# 7. Imap::Message.new(message_id, imap_client).subject
# 8. Imap::Message.new(message_id, imap_client).from
# 9. Imap::Message.new(message_id, imap_client).to
# 10. Imap::Message.new(message_id, imap_client).received_at
# 11. Imap::Message.new(message_id, imap_client).attachment_filenames
# 12. Imap::Message.new(message_id, imap_client).source

require 'time'

require_relative './Search'

class Imap
  class Message

    # What one fetch brings back, since the round trip costs the same whether it
    # asks for one of these or for all of them.
    FETCH_ATTRIBUTES = %w{UID FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODYSTRUCTURE}
    SLICE = 200
    ENCODED_WORD = /=\?([^?]+)\?([BbQq])\?([^?]*)\?=/

    class << self

      def search(imap_client, **search_criteria)
        self.for(imap_client, Imap::Search.new(imap_client, search_criteria).message_ids)
      end
      alias_method :find, :search

      # One fetch for a slice of messages rather than one per attribute per
      # message.  A hundred messages cost a round trip apiece for the subject and
      # another apiece for the from; they cost one for the hundred now.
      #
      # new and not Imap::Message.new, so that a subclass gets its own kind back.
      def for(imap_client, message_ids)
        message_ids.each_slice(SLICE).flat_map do |slice|
          imap_client.imap.fetch(slice, FETCH_ATTRIBUTES).collect do |data|
            new(data.seqno, imap_client, data)
          end
        end
      end

      # RFC 2047: =?charset?B?base64?= and =?charset?Q?quoted-printable?=, which
      # headers carry wherever the subject or a name is not ASCII.
      def decode(value)
        return nil if value.nil?
        value.to_s.gsub(/(?<=\?=)\s+(?==\?)/, '').gsub(ENCODED_WORD){decode_word($1, $2, $3)}
      end

      private

      def decode_word(charset, encoding, text)
        bytes =
          if encoding.upcase == 'B'
            text.unpack1('m')
          else
            text.tr('_', ' ').gsub(/=([0-9A-Fa-f]{2})/){$1.hex.chr}
          end
        bytes.force_encoding(charset.split('*').first).encode('UTF-8', invalid: :replace, undef: :replace)
      rescue StandardError
        text
      end

    end # class << self

    attr_accessor :imap_client
    attr_accessor :message_id

    def uid
      data.uid
    end

    def flags
      data.flags || []
    end

    def seen?
      flags.include?(:Seen)
    end

    def size
      data.size.to_i
    end

    # When the server took delivery, which is what a mailbox is ordered by.
    def received_at
      @received_at ||= data.internaldate
    end

    # When the sender says they sent it, which is the Date header and is theirs
    # to get wrong.  Time.parse and not Net::IMAP.decode_time: the envelope
    # carries the RFC 5322 header, not IMAP's own date-time.
    def sent_at
      @sent_at ||= to_time(envelope && envelope.date)
    end

    def subject
      @subject ||= Message.decode(envelope && envelope.subject).to_s.tr("\r\n", ' ').strip
    end

    def from
      @from ||= address_to_s(envelope.from && envelope.from.first)
    end

    def from_address
      @from_address ||= address_only(envelope.from && envelope.from.first)
    end

    def from_domain
      @from_domain ||= from_address && from_address.split('@').last.to_s.downcase
    end

    def to
      @to ||= addresses(envelope.to)
    end

    def cc
      @cc ||= addresses(envelope.cc)
    end

    # IMAP cannot search upon an attachment, but the bodystructure names them and
    # arrives with the rest.
    def attachment?
      !attachment_filenames.empty?
    end

    def attachment_filenames
      @attachment_filenames ||= filenames_in(data.bodystructure)
    end

    def body
      @body ||= fetch_data('BODY.PEEK[TEXT]').first.text
    end

    # The whole message, headers and all, for whatever wants to parse MIME.
    def source
      @source ||= fetch_data('BODY.PEEK[]').first.message
    end

    def urls
      body.scan(/https?:\/\/[\S]+/)
    end

    def mark_as_seen
      imap_client.imap.store(@message_id, '+FLAGS', [:Seen])
    end
    alias_method :mark_as_read, :mark_as_seen

    private

    def initialize(message_id = nil, imap_client = nil, data = nil)
      @message_id = message_id
      @imap_client = imap_client
      @data = data
    end

    # The Net::IMAP::FetchData itself rather than its attr hash, since it reads
    # every one of these attributes already and decodes the internaldate to a
    # Time along the way.  Prefetched where search() built this, fetched where
    # the caller built it.
    def data
      @data ||= fetch_data(*FETCH_ATTRIBUTES).first
    end

    def envelope
      data.envelope
    end

    def to_time(value)
      return value if value.is_a?(Time)
      value.nil? || value.to_s.empty? ? nil : Time.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def addresses(list)
      (list || []).collect{|address| address_to_s(address)}.compact
    end

    def address_only(address)
      address && [address.mailbox, address.host].compact.join('@')
    end

    def address_to_s(address)
      return nil unless address
      email = address_only(address)
      name = Message.decode(address.name).to_s.strip
      name.empty? ? email : "#{name} <#{email}>"
    end

    def filenames_in(structure)
      return [] unless structure
      return structure.parts.flat_map{|part| filenames_in(part)} if structure.respond_to?(:parts) && structure.parts
      return filenames_in(structure.body) if structure.respond_to?(:body) && structure.body
      [filename_of(structure)].compact
    end

    # The disposition names it where the sender set one, the content type's NAME
    # where they did not.
    def filename_of(part)
      name = disposition_filename(part) || parameter_filename(part)
      name.nil? || name.to_s.strip.empty? ? nil : Message.decode(name).strip
    end

    def disposition_filename(part)
      disposition = part.respond_to?(:disposition) ? part.disposition : nil
      disposition && disposition.param ? disposition.param['FILENAME'] : nil
    end

    def parameter_filename(part)
      part.respond_to?(:param) && part.param ? part.param['NAME'] : nil
    end

    def fetch_data(*fetch_attributes)
      @fetch_data = imap_client.imap.fetch(message_id, [*fetch_attributes])
    end
  end
end
