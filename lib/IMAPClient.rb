#!/usr/bin/env ruby
# IMAPClient

# 20131116
# 0.0.3

# Usage:
# imap_client = IMAPClient.setup(server: 'mail.thoran.com', username: 'code@thoran.com', password: 'bigsecret')
# urls = imap_client.urls(from: 'no_reply@example.com', subject: 'Payday Loans', seen: false)
# imap_client.bye

require 'net/imap'
require 'String/capture'

class IMAPClient

  class << self

    def setup(config)
      raise unless config[:server]
      imap_client = IMAPClient.new(config)
      if config[:username] && config[:password]
        imap_client.login(config[:username], config[:password])
      end
      if config[:mailbox]
        imap_client.mailbox = config[:mailbox]
      end
      imap_client
    end

  end # class << self

  attr_accessor :server
  attr_accessor :username
  attr_accessor :password

  def initialize(config = {})
    @server = config[:server]
    @username = config[:username]
    @password = config[:password]
    @mailbox = config[:mailbox]
  end

  def login(username = nil, password = nil)
    username ||= self.username
    password ||= self.password
    begin
      imap.login(username, password)
      true
    rescue
      false
    end
  end

  def mailbox
    @mailbox || 'INBOX'
  end

  def mailbox=(mailbox)
    @mailbox = mailbox
    imap.select(mailbox)
  end

  def find(criteria = {})
    imap.search(to_imap_search_criteria(criteria))
  end
  alias_method :search, :find

  def urls(criteria = {})
    message_ids = search(criteria)
    message_ids.collect do |message_id|
      begin
        body = imap.fetch(message_id, 'BODY[TEXT]').first.attr['BODY[TEXT]']
        if block_given?
          yield body.capture(/(https?:\/\/[\S]+)/)
        else
          body.capture(/(https?:\/\/[\S]+)/)
        end
      ensure
        imap.store(message_id, '+FLAGS', [:Seen])
      end
    end
  end

  def bye
    logout
    disconnect
  end

  def logout
    imap.logout
  end

  def disconnect
    imap.disconnect
  end

  private

  def imap
    @imap ||= Net::IMAP.new(server)
  end

  def non_boolean_search_criteria?(key)
    %w{subject from to}.include?(key.to_s)
  end

  def boolean_search_criteria?(key)
    %{seen deleted}.include?(key.to_s)
  end

  def to_imap_search_criteria(criteria = {})
    criteria.inject([]) do |m,kv|
      key = kv.first
      value = kv.last
      case
      when non_boolean_search_criteria?(key)
        m << kv.first.to_s.upcase
        m << kv.last
      when boolean_search_criteria?(kv.first)
        if kv.last
          m << kv.first.to_s.upcase
        else
          m << 'NOT'
          m << kv.first.to_s.upcase
        end
      end
    end
  end

end
