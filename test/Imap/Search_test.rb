# test/Imap/Search_test.rb

require_relative '../test_helper'

describe Imap::Search do
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

  let(:search) do
    Imap::Search.new(client, {})
  end

  describe '#to_imap_search_keys' do
    it 'converts general search keys' do
      test_search = Imap::Search.new(client, from: 'test@example.com')
      keys = test_search.to_imap_search_keys
      _(keys).must_include 'FROM'
      _(keys).must_include 'test@example.com'
    end

    it 'converts boolean search keys' do
      test_search = Imap::Search.new(client, seen: false)
      keys = test_search.to_imap_search_keys
      _(keys).must_include 'NOT'
      _(keys).must_include 'SEEN'
    end

    it 'raises upon a key which is neither' do
      _{Imap::Search.new(client, bogus: 'x').to_imap_search_keys}.must_raise Imap::Search::UnknownSearchKey
    end

    it 'handles multiple criteria' do
      test_search = Imap::Search.new(client, from: 'test@example.com', seen: true)
      keys = test_search.to_imap_search_keys
      _(keys.length).must_be :>, 2
    end
  end

  describe '#message_ids' do
    it 'returns an array of message IDs' do
      ids = search.message_ids
      _(ids).must_be_instance_of Array
    end

    it 'has all alias' do
      _((search.method(:all) == search.method(:message_ids))).must_equal true
    end
  end

  describe '#boolean_operator?' do
    it 'returns true for boolean operators' do
      _(search.boolean_operator?('SEEN')).must_equal true
      _(search.boolean_operator?('ANSWERED')).must_equal true
    end

    it 'returns false for general operators' do
      _(search.boolean_operator?('FROM')).must_equal false
    end
  end

  describe '#general_operator?' do
    it 'returns true for general operators' do
      _(search.general_operator?('FROM')).must_equal true
      _(search.general_operator?('SUBJECT')).must_equal true
    end

    it 'returns false for boolean operators' do
      _(search.general_operator?('SEEN')).must_equal false
    end
  end

  describe '#initialize' do
    it 'accepts imap_client parameter' do
      test_search = Imap::Search.new(client)
      _(test_search.imap_client).must_equal client
    end

    it 'accepts criteria parameter' do
      test_search = Imap::Search.new(client, from: 'test@example.com')
      _(test_search.criteria).must_equal({ from: 'test@example.com' })
    end

    it 'defaults criteria to empty hash' do
      test_search = Imap::Search.new(client)
      _(test_search.criteria).must_equal({})
    end
  end
end
