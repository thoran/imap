# Imap/Message.rb
# Imap::Message

# Usage:
# 1. Imap::Message.search(imap_client, {from: 'noreply@example.com'})
# 2. Imap::Message.new(message_id, imap_client)
# 3. Imap::Message.new(message_id, imap_client).body
# 4. Imap::Message.new(message_id, imap_client).urls
# 5. Imap::Message.new(message_id, imap_client).mark_as_read
# 6. Imap::Message.new(message_id, imap_client).subject
# 7. Imap::Message.new(message_id, imap_client).from
# 8. Imap::Message.new(message_id, imap_client).to

require_relative './Search'

class Imap
  class Message

    SLICE = 200
    class << self

      # One fetch for a slice of messages rather than one per attribute per
      # message.  A hundred messages cost a round trip apiece for the subject and
      # another apiece for the from; they cost one for the hundred now.
      def search(imap_client, **search_criteria)
        message_ids = Imap::Search.new(imap_client, search_criteria).message_ids
        message_ids.each_slice(SLICE).flat_map do |slice|
          imap_client.imap.fetch(slice, ['ENVELOPE']).collect do |data|
            Imap::Message.new(data.seqno, imap_client, data.attr)
          end
        end
      end
      alias_method :find, :search

    end # class << self

    attr_accessor :imap_client
    attr_accessor :message_id

    def body
      @body ||= fetch_data('BODY.PEEK[TEXT]').first.attr['BODY[TEXT]']
    end

    def subject
      @subject ||= envelope.subject.to_s.strip
    end

    def from
      @from ||= address_to_s(envelope.from && envelope.from.first)
    end

    def to
      @to ||= (envelope.to || []).collect{|address| address_to_s(address)}
    end

    def urls
      body.scan(/https?:\/\/[\S]+/)
    end

    def mark_as_seen
      imap_client.imap.store(@message_id, '+FLAGS', [:Seen])
    end
    alias_method :mark_as_read, :mark_as_seen

    private

    def initialize(message_id = nil, imap_client = nil, attrs = nil)
      @message_id = message_id
      @imap_client = imap_client
      @attrs = attrs
    end

    # Prefetched where search() built this, fetched where the caller built it.
    def envelope
      @envelope ||= (@attrs && @attrs['ENVELOPE']) || fetch_data('ENVELOPE').first.attr['ENVELOPE']
    end

    def address_to_s(address)
      return nil unless address
      email = [address.mailbox, address.host].compact.join('@')
      address.name.to_s.empty? ? email : "#{address.name} <#{email}>"
    end

    def fetch_data(*attrs)
      @fetch_data = imap_client.imap.fetch(message_id, [*attrs])
    end
  end
end
