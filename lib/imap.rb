# imap.rb
# Imap

require 'net/imap'
require_relative './Imap/Message'

class Imap
  class << self

    def setup(config)
      raise ArgumentError, "Server must be specified" unless config[:server]
      imap_client = Imap.new(**config)
      if config[:username] && config[:password]
        imap_client.login(username: config[:username], password: config[:password])
      end
      if config[:mailbox]
        imap_client.mailbox = config[:mailbox]
      end
      imap_client
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
