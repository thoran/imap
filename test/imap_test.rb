# test/imap_test.rb

require_relative './test_helper'

describe Imap do
  let(:client) do
    Net::IMAP.stub(:new, MockIMAP.new('imap.example.com', ssl: true)) do
      Imap.setup(
        server: 'imap.example.com',
        username: 'user@example.com',
        password: 'secret',
        mailbox: 'INBOX'
      )
    end
  end

  describe ".setup" do
    it 'creates a new client instance' do
      _(client).must_be_instance_of(Imap)
    end

    it 'requires a server parameter' do
      _(proc{Imap.setup({})}).must_raise(ArgumentError)
    end

    it 'sets the server' do
      _(client.server).must_equal 'imap.example.com'
    end

    it 'defaults ssl to true' do
      _(client.ssl?).must_equal true
    end

    it 'defaults mailbox to INBOX' do
      _(client.mailbox).must_equal 'INBOX'
    end
  end

  describe ".setup, upon a login which does not take" do
    def refusing_mock
      mock = MockIMAP.new('imap.example.com', ssl: true)
      def mock.login(username, password)
        raise Net::IMAP::NoResponseError, OpenStruct.new(data: OpenStruct.new(text: 'Authentication failed'))
      end
      mock
    end

    it 'raises rather than handing back a connection which is not logged in' do
      Net::IMAP.stub(:new, refusing_mock) do
        error = _(proc{Imap.setup(server: 'imap.example.com', username: 'user', password: 'wrong')}).must_raise(Imap::LoginFailed)
        _(error.message).must_equal 'imap.example.com refused user'
      end
    end

    it 'does not go on to select a mailbox' do
      mock = refusing_mock
      Net::IMAP.stub(:new, mock) do
        _(proc{Imap.setup(server: 'imap.example.com', username: 'user', password: 'wrong', mailbox: 'INBOX')}).must_raise(Imap::LoginFailed)
      end
      _(mock.select_called).must_equal false
    end

    it 'raises where only one of the pair is given, rather than skipping the login' do
      Net::IMAP.stub(:new, MockIMAP.new('imap.example.com', ssl: true)) do
        error = _(proc{Imap.setup(server: 'imap.example.com', username: 'user')}).must_raise(Imap::LoginFailed)
        _(error.message).must_match(/only the username was given/)
        _(proc{Imap.setup(server: 'imap.example.com', password: 'secret')}).must_raise(Imap::LoginFailed)
      end
    end

    it 'does not log in at all where neither is given' do
      mock = MockIMAP.new('imap.example.com', ssl: true)
      Net::IMAP.stub(:new, mock) do
        _(Imap.setup(server: 'imap.example.com')).must_be_instance_of Imap
      end
      _(mock.login_called).must_equal false
    end
  end

  describe "#login" do
    it 'returns true on successful login' do
      Net::IMAP.stub(:new, MockIMAP.new('imap.example.com', ssl: true)) do
        test_client = Imap.new(server: 'imap.example.com')
        result = test_client.login(username: 'user', password: 'pass')
        _(result).must_equal true
      end
    end

    it 'returns false on failed login' do
      mock = MockIMAP.new('imap.example.com', ssl: true)
      def mock.login(username, password)
        mock_response = OpenStruct.new(data: OpenStruct.new(text: 'Authentication failed'))
        raise Net::IMAP::BadResponseError, mock_response
      end

      Net::IMAP.stub(:new, mock) do
        test_client = Imap.new(server: 'imap.example.com')
        result = test_client.login(username: 'user', password: 'wrong')
        _(result).must_equal false
      end
    end
  end

  describe "#mailbox=" do
    it 'sets the mailbox' do
      Net::IMAP.stub(:new, MockIMAP.new('imap.example.com', ssl: true)) do
        test_client = Imap.new(server: 'imap.example.com')
        test_client.mailbox = 'Sent'
        _(test_client.mailbox).must_equal 'Sent'
      end
    end
  end

  describe "#mailboxes" do
    it 'names every mailbox which can be selected' do
      _(client.mailboxes).must_equal ['INBOX', 'Archive/2026']
    end

    it 'leaves out the \\Noselect containers' do
      _(client.mailboxes).wont_include 'Archive'
    end
  end

  describe "#search" do
    it 'returns an array of Message objects' do
      Net::IMAP.stub(:new, MockIMAP.new('imap.example.com', ssl: true)) do
        test_client = Imap.setup(
          server: 'imap.example.com',
          username: 'user',
          password: 'pass'
        )
        messages = test_client.search(from: 'test@example.com')
        _(messages).must_be_instance_of Array
        _(messages.first).must_be_instance_of Imap::Message
      end
    end

    it 'has messages and find aliases' do
      _((client.method(:messages) == client.method(:search))).must_equal true
      _((client.method(:find) == client.method(:search))).must_equal true
    end
  end

  describe "#initialize" do
    it 'accepts server parameter' do
      test_client = Imap.new(server: 'mail.example.com')
      _(test_client.server).must_equal 'mail.example.com'
    end

    it 'accepts ssl parameter' do
      test_client = Imap.new(server: 'mail.example.com', ssl: false)
      _(test_client.ssl?).must_equal false
    end

    it 'accepts username parameter' do
      test_client = Imap.new(server: 'mail.example.com', username: 'test@example.com')
      _(test_client.username).must_equal 'test@example.com'
    end

    it 'accepts password parameter' do
      test_client = Imap.new(server: 'mail.example.com', password: 'secret')
      _(test_client.password).must_equal 'secret'
    end

    it 'accepts mailbox parameter' do
      test_client = Imap.new(server: 'mail.example.com', mailbox: 'Sent')
      _(test_client.mailbox).must_equal 'Sent'
    end
  end
end
