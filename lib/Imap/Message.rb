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
    class << self

      def search(imap_client, **search_criteria)
        message_ids = Imap::Search.new(imap_client, search_criteria).message_ids
        message_ids.collect{|message_id| Imap::Message.new(message_id, imap_client)}
      end
      alias_method :find, :search

    end # class << self

    attr_accessor :imap_client
    attr_accessor :message_id

    def body
      @body ||= fetch_data('BODY.PEEK[TEXT]').first.attr['BODY[TEXT]']
    end

    def subject
      @subject ||= fetch_data('BODY[HEADER.FIELDS (SUBJECT)]').first.attr['BODY[HEADER.FIELDS (SUBJECT)]'].sub(/^Subject: /, '').strip
    end

    def from
      @from ||= fetch_data('BODY[HEADER.FIELDS (FROM)]').first.attr['BODY[HEADER.FIELDS (FROM)]'].sub(/^From: /, '').strip
    end

    def to
      @to ||= (fetch_data('ENVELOPE').first.attr['ENVELOPE'].to || []).map{|addr| addr.mailbox + '@' + addr.host}
    end

    def urls
      body.scan(/https?:\/\/[\S]+/)
    end

    def mark_as_seen
      imap_client.imap.store(@message_id, '+FLAGS', [:Seen])
    end
    alias_method :mark_as_read, :mark_as_seen

    private

    def initialize(message_id = nil, imap_client = nil)
      @message_id = message_id
      @imap_client = imap_client
    end

    def fetch_data(*attrs)
      @fetch_data = imap_client.imap.fetch(message_id, [*attrs])
    end
  end
end
