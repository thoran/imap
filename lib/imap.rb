# imap.rb
# Imap

require 'net/imap'
require_relative './Imap/Message'
require_relative './Imap/VERSION'

class Imap
  class LoginFailed < StandardError; end

  class << self

    def setup(config)
      raise ArgumentError, "Server must be specified" unless config[:server]
      imap_client = Imap.new(**config)
      login!(imap_client, config) if config[:username] || config[:password]
      imap_client.mailbox = config[:mailbox] if config[:mailbox]
      imap_client
    end

    private

    # A half-given pair is a mistake rather than a reason not to log in, and a
    # refusal is not something to carry on from: what follows is a connection
    # which answers BAD to whatever is asked of it, several commands away from
    # the fault.
    def login!(imap_client, config)
      unless config[:username] && config[:password]
        raise LoginFailed, "#{config[:server]} wants both a username and a password; only the #{config[:username] ? 'username' : 'password'} was given"
      end
      unless imap_client.login(username: config[:username], password: config[:password])
        raise LoginFailed, "#{config[:server]} refused #{config[:username]}"
      end
    end

  end # class << self

  attr_accessor :server
  attr_accessor :ssl
  attr_accessor :username
  attr_accessor :password
  attr_reader :mailbox

  def login(username: nil, password: nil)
    username ||= @username
    password ||= @password
    begin
      imap.login(username, password)
      true
    rescue Net::IMAP::NoResponseError, Net::IMAP::BadResponseError
      false
    end
  end

  def mailbox=(mailbox)
    @mailbox = mailbox
    imap.select(mailbox)
  end

  # Every mailbox which can be selected, the \Noselect containers left out.
  def mailboxes
    (imap.list('', '*') || []).reject{|mailbox| mailbox.attr.include?(:Noselect)}.collect(&:name)
  end

  def search(criteria = {})
    Imap::Message.search(self, **criteria)
  end
  alias_method :messages, :search
  alias_method :find, :search

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

  def imap
    @imap ||= Net::IMAP.new(server, ssl: @ssl)
  end

  def ssl?
    @ssl
  end

  private

  def initialize(server:, ssl: true, username: nil, password: nil, mailbox: 'INBOX')
    @server = server
    @ssl = ssl
    @username = username
    @password = password
    @mailbox = mailbox
  end
end
