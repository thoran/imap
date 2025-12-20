# ImapClient.rb
# ImapClient

# 20190916
# 0.2.1

# Usage:
# imap_client = IMAPClient.setup(server: 'mail.thoran.com', username: 'code@thoran.com', password: 'bigsecret')
# messages = imap_client.search(from: 'no_reply@example.com', subject: 'Payday Loans', seen: false)
# imap_client.bye

require 'net/imap'
require 'Module/alias_methods'
require_relative './ImapClient/Message'

class ImapClient

  class << self

    def setup(config)
      raise unless config[:server]
      imap_client = ImapClient.new(config)
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

  def initialize(server:, ssl: true, username: nil, password: nil, mailbox: 'INBOX')
    @server = server
    @ssl = ssl
    @username = username
    @password = password
    @mailbox = mailbox
  end

  def login(username: nil, password: nil)
    username ||= @username
    password ||= @password
    begin
      imap.login(username, password)
      true
    rescue
      false
    end
  end

  def mailbox=(mailbox)
    @mailbox = mailbox
    imap.select(mailbox)
  end

  def search(criteria = {})
    ImapClient::Message.search(self, criteria)
  end
  alias_methods :messages, :find, :search

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

end
