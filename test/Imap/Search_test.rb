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

  describe 'OR, NOT and HEADER' do
    def keys(criteria) = Imap::Search.new(client, criteria).to_imap_search_keys

    it 'answers ALL, which every key list named and neither operator list held' do
      _(keys(all: true)).must_equal ['ALL']
    end

    it 'ands a list of criteria hashes for ALL_OF' do
      _(keys(all_of: [{text: 'invoice'}, {text: 'overdue'}])).must_equal ['TEXT', 'invoice', 'TEXT', 'overdue']
    end

    it 'is how the one key carries more than one term, a hash holding it once' do
      _(keys({text: 'invoice'}.merge(text: 'overdue'))).must_equal ['TEXT', 'overdue']
      _(keys(all_of: [{text: 'invoice'}, {text: 'overdue'}])).must_equal ['TEXT', 'invoice', 'TEXT', 'overdue']
    end

    it 'nests OR and NOT inside ALL_OF' do
      _(keys(all_of: [{not: {text: 'draft'}}, {or: [{from: 'a@x'}, {to: 'b@y'}]}])).must_equal ['NOT', 'TEXT', 'draft', 'OR', 'FROM', 'a@x', 'TO', 'b@y']
    end

    it 'sits beside the plain keys' do
      _(keys(since: '1-Sep-2026', all_of: [{text: 'a'}, {text: 'b'}])).must_equal ['SINCE', '1-Sep-2026', 'TEXT', 'a', 'TEXT', 'b']
    end

    it 'takes two criteria hashes for OR' do
      _(keys(or: [{from: 'a@x'}, {to: 'b@y'}])).must_equal ['OR', 'FROM', 'a@x', 'TO', 'b@y']
    end

    it 'nests OR where there are more than two, it taking only two' do
      _(keys(or: [{from: 'a@x'}, {to: 'b@y'}, {cc: 'c@z'}])).must_equal ['OR', 'OR', 'FROM', 'a@x', 'TO', 'b@y', 'CC', 'c@z']
    end

    it 'negates a criterion for NOT' do
      _(keys(not: {subject: 'Payday'})).must_equal ['NOT', 'SUBJECT', 'Payday']
    end

    it 'negates each on its own where NOT carries more than one, it taking only one' do
      _(keys(not: {subject: 'Payday', seen: true})).must_equal ['NOT', 'SUBJECT', 'Payday', 'NOT', 'SEEN']
    end

    it 'takes a field and a value for HEADER' do
      _(keys(header: ['List-Id', 'announce'])).must_equal ['HEADER', 'List-Id', 'announce']
    end

    it 'mixes with the plain keys' do
      _(keys(since: '1-Sep-2026', or: [{from: 'a@x'}, {to: 'b@y'}])).must_equal ['SINCE', '1-Sep-2026', 'OR', 'FROM', 'a@x', 'TO', 'b@y']
    end
  end

  describe 'the chaining interface' do
    it 'names the keys in lower case' do
      _(Imap::Search.new(client).from('x@y.com').criteria).must_equal({FROM: 'x@y.com'})
    end

    it 'returns itself, so that it chains' do
      search = Imap::Search.new(client)
      _(search.from('x@y.com')).must_be_same_as search
    end

    it 'negates a general key' do
      _(Imap::Search.new(client).not.subject('Payday Loans').to_imap_search_keys).must_equal ['NOT', 'SUBJECT', 'Payday Loans']
    end

    it 'negates a boolean key' do
      _(Imap::Search.new(client).not.seen.to_imap_search_keys).must_equal ['NOT', 'SEEN']
    end

    it 'negates what follows immediately and nothing after it' do
      keys = Imap::Search.new(client).not.subject('Payday Loans').answered.from('noreply@example.com').to_imap_search_keys
      _(keys).must_equal ['NOT', 'SUBJECT', 'Payday Loans', 'ANSWERED', 'FROM', 'noreply@example.com']
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
