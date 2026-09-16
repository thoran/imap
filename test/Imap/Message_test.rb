# test/Imap/Message_test.rb

require_relative '../test_helper'

describe Imap::Message do
  let(:client) do
    mock_imap = MockIMAP.new('imap.example.com', ssl: true)
    Net::IMAP.stub(:new, mock_imap) do
      Imap.setup(
        server: 'imap.example.com',
        username: 'user@example.com',
        password: 'secret'
      )
    end
  end

  let(:imap_message) do
    Imap::Message.new(1, client)
  end

  describe '.search' do
    it 'returns an array of messages' do
      messages = Imap::Message.search(client, from: 'test@example.com')
      _(messages).must_be_instance_of Array
      _(messages.first).must_be_instance_of Imap::Message
    end

    it 'has find alias' do
      _((Imap::Message.method(:find) == Imap::Message.method(:search))).must_equal true
    end
  end

  describe '#body' do
    it 'returns the message body' do
      _(imap_message.body).must_match(/Mock body/)
    end

    it 'caches the result' do
      first_call = imap_message.body
      second_call = imap_message.body
      _(first_call.object_id).must_equal second_call.object_id
    end

    it 'peeks, so that reading a body does not mark it seen' do
      imap_message.body
      _(client.imap.fetched_attrs).must_include 'BODY.PEEK[TEXT]'
    end
  end

  describe '#subject' do
    it 'returns the subject without prefix' do
      _(imap_message.subject).must_match(/Mock Subject/)
      _(imap_message.subject).wont_match(/^Subject:/)
    end

    it 'strips whitespace' do
      _(imap_message.subject).must_equal(imap_message.subject.strip)
    end
  end

  describe '#from' do
    it 'returns the from address' do
      _(imap_message.from).must_match(/sender@example.com/)
    end

    it 'removes From: prefix' do
      _(imap_message.from).wont_match(/^From:/)
    end
  end

  describe '#to' do
    it 'returns an array of email addresses' do
      addresses = imap_message.to
      _(addresses).must_be_instance_of(Array)
      _(addresses.first).must_match(/@/)
    end

    it 'formats addresses correctly' do
      addresses = imap_message.to
      _(addresses.first).must_equal('user@example.com')
    end

    it 'is empty where the envelope carries no to' do
      _(Imap::Message.new(99, client).to).must_equal []
    end
  end

  describe '#urls' do
    it 'extracts http URLs from body' do
      imap_message.stub(:body, 'Check out http://example.com and https://test.com') do
        urls = imap_message.urls
        _(urls).must_include('http://example.com')
        _(urls).must_include('https://test.com')
      end
    end

    it 'returns empty array when no URLs' do
      imap_message.stub(:body, 'No URLs here') do
        _(urls = imap_message.urls).must_be_empty
      end
    end
  end

  describe '#mark_as_seen' do
    it 'marks the message as seen' do
      _(imap_message.mark_as_seen).must_be_nil
    end

    it 'has mark_as_read alias' do
      _((imap_message.method(:mark_as_read) == imap_message.method(:mark_as_seen))).must_equal true
    end
  end

  describe '#initialize' do
    it 'accepts message_id and imap_client' do
      test_message = Imap::Message.new(42, client)
      _(test_message.message_id).must_equal(42)
      _(test_message.imap_client).must_equal(client)
    end
  end
end
