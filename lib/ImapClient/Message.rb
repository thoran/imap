# ImapClient/Message.rb
# ImapClient::Message

# Usage:
# ImapClient::Message.search

# Notes: 
# 1. List of search keys taken from RFC 3501 ("INTERNET MESSAGE ACCESS PROTOCOL - VERSION 4rev1"), http://tools.ietf.org/html/rfc3501.

require 'Array/extract_optionsX'

require_relative '../ImapClient/Search'

class ImapClient
  class Message

    class << self

      def search(imap_client, *args)
        search_criteria = args.extract_options!
        message_ids = ImapClient::Search.new(search_criteria, imap_client).message_ids
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

    def urls
      body.scan(/https?:\/\/[\S]+/)
    end

    private

    def fetch_data(*attrs)
      @fetch_data = imap_client.imap.fetch(message_id, [*attrs])
    end

  end
end
