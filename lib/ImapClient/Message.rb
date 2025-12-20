# ImapClient/Message.rb
# ImapClient::Message

# Usage:
# 1. ImapClient::Message.search(imap_client, {from: 'noreply@example.com'})
# 2. ImapClient::Message.new(message_id, imap_client)
# 3. ImapClient::Message.new(message_id, imap_client).body
# 4. ImapClient::Message.new(message_id, imap_client).urls
# 5. ImapClient::Message.new(message_id, imap_client).mark_as_read
# 6. ImapClient::Message.new(message_id, imap_client).subject

require 'Array/extract_optionsX'
require_relative './Search'

class ImapClient
  class Message

    class << self

      def search(imap_client, *args)
        search_criteria = args.extract_options!
        message_ids = ImapClient::Search.new(imap_client, search_criteria).message_ids
        message_ids.collect{|message_id| ImapClient::Message.new(message_id, imap_client)}
      end
      alias_method :find, :search

    end # class << self

    attr_accessor :imap_client
    attr_accessor :message_id

    def initialize(message_id = nil, imap_client = nil)
      @message_id = message_id
      @imap_client = imap_client
    end

    def body
      @body ||= fetch_data('BODY[TEXT]').first.attr['BODY[TEXT]']
    end

    def subject
      @subject ||= fetch_data('BODY[HEADER.FIELDS (SUBJECT)]').first.attr['BODY[HEADER.FIELDS (SUBJECT)]'].sub(/^Subject: /, '').strip
    end

    def from
      @from ||= fetch_data('BODY[HEADER.FIELDS (FROM)]').first.attr['BODY[HEADER.FIELDS (FROM)]'].sub(/^From: /, '').strip
    end

    def urls
      body.scan(/https?:\/\/[\S]+/)
    end

    def mark_as_seen
      imap_client.imap.store(@message_id, '+FLAGS', [:Seen])
    end
    alias_method :mark_as_read, :mark_as_seen

    private

    def fetch_data(*attrs)
      @fetch_data = imap_client.imap.fetch(message_id, [*attrs])
    end

  end
end
