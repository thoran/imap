#!/usr/bin/env ruby
# IMAPClient

# 20131109..12
# 0.0.0

require 'net/imap'


class IMAPClient

  attr_accessor :server
  attr_accessor :username
  attr_accessor :password

  def setup(config = {})
    @server = config[:server]
    @username = config[:username]
    @password = config[:password]
    imap = Net::IMAP.new(@server)
  end

  def login(username = nil, password = nil)
    imap.login(username, password)
  end

  def mailbox
    @mailbox || 'INBOX'
  end

  def mailbox=(mailbox)
    @mailbox = mailbox
    imap.select(@mailbox)
  end

  def search(criteria = {})
    imap.search(to_imap_search_criteria(criteria))
  end

  def urls(message_ids)
    message_ids.collect do |message_id|
      begin
        body = imap.fetch(message_id,'BODY[TEXT]').first.attr['BODY[TEXT]']
        if block_given?
          yield body.capture(/(https?:\/\/[\S]+)/)
        else
          body.capture(/(https?:\/\/[\S]+)/)          
        end
      ensure
        imap.store(message_id, "+FLAGS", [:Seen])
      end
    end
  end

  def logout
    imap.logout
  end

  def disconnect
    imap.disconnect
  end

  private

  def non_boolean_search_criteria?(key)
    %w{subject from to}.include?(key)
  end

  def boolean_search_criteria?(key)
    %{seen deleted}.include?(key)
  end

  def to_imap_search_criteria(criteria = {})
    criteria.inject([]) do |m,kv|
      case 
      when non_boolean_search_criteria?(key)
        m << kv.first.upcase
        m << kv.last
      when boolean_search_criteria?(kv.first)
        if kv.last
          m << kv.first
        else
          m << 'NOT'
          m << kv.first
        end
      end
    end
  end

end
