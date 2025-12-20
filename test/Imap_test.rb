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
