# Imap/Search.rb
# Imap::Search

# Usage:
# 1. Imap::Search.new(imap_client).not.subject('Payday Loans').answered.from('noreply@example.com').all
# 2. Imap::Search.new(imap_client, {from: 'noreply@example.com', answered: true})

# Notes:
# 1. List of search keys taken from RFC-3501 (INTERNET MESSAGE ACCESS PROTOCOL - VERSION 4rev1), http://tools.ietf.org/html/rfc3501.

class Imap
  class Search

    class UnknownSearchKey < ArgumentError; end

    # A general key carries its value; negating one has to carry both, the hash
    # having nowhere else to put it.  A boolean key needs none of this: false
    # already reads as NOT.
    Negated = Struct.new(:value)

    ALL_SEARCH_KEYS = %w{
      ALL
      ANSWERED
      BCC
      BEFORE
      BODY
      CC
      DELETED
      DRAFT
      FLAGGED
      FROM
      HEADER
      KEYWORD
      LARGER
      NEW
      NOT
      OLD
      ON
      OR
      RECENT
      SEEN
      SENTBEFORE
      SENTON
      SENTSINCE
      SINCE
      SMALLER
      SUBJECT
      TEXT
      TO
      UID
      UNANSWERED
      UNDELETED
      UNDRAFT
      UNFLAGGED
      UNKEYWORD
      UNSEEN
    }

    BOOLEAN_SEARCH_KEYS = %w{
      ANSWERED UNANSWERED
      DELETED UNDELETED
      DRAFT UNDRAFT
      FLAGGED UNFLAGGED
      NEW
      OLD
      RECENT
      SEEN UNSEEN
    }

    GENERAL_SEARCH_KEYS = %w{
      BCC
      BEFORE
      BODY
      CC
      FROM
      HEADER
      KEYWORD UNKEYWORD
      LARGER
      ON
      SENTBEFORE
      SENTON
      SENTSINCE
      SINCE
      SMALLER
      SUBJECT
      TEXT
      TO
      UID
    }

    BOOLEAN_SEARCH_KEYS.each do |boolean_search_key|
      define_method boolean_search_key.downcase do |value = true|
        criteria.merge!(boolean_search_key.to_sym => negating? ? !value : value)
        self
      end
    end

    GENERAL_SEARCH_KEYS.each do |general_search_key|
      define_method general_search_key.downcase do |value|
        criteria.merge!(general_search_key.to_sym => negating? ? Negated.new(value) : value)
        self
      end
    end

    # Applies to what follows immediately, and to nothing after that.
    def not
      @negate = true
      self
    end

    attr_accessor :criteria
    attr_accessor :imap_client

    def general_operator?(search_key)
      GENERAL_SEARCH_KEYS.include?(search_key)
    end

    def boolean_operator?(search_key)
      BOOLEAN_SEARCH_KEYS.include?(search_key)
    end

    def to_imap_search_keys
      criteria.inject([]) do |m, kv|
        key, value = kv.first.to_s.upcase, kv.last
        case
        when key == 'OR'
          m << any_of(value)
        when key == 'NOT'
          m << none_of(value)
        when general_operator?(key)
          m << general_to_imap_search_key(key, value)
        when boolean_operator?(key)
          m << boolean_to_imap_search_key(key, value)
        else
          raise UnknownSearchKey, "no such search key: #{key}"
        end
      end.flatten
    end

    # OR takes two keys and no more, so three criteria nest: OR OR a b c.  Each
    # is a criteria hash of its own, so either side may nest further.
    def any_of(criteria_hashes)
      criteria_hashes.collect{|criteria_hash| Search.new(nil, criteria_hash).to_imap_search_keys}.inject{|m, keys| ['OR'] + m + keys}
    end

    # NOT takes one key, so each criterion is negated on its own: NOT a NOT b.
    def none_of(criteria_hash)
      criteria_hash.inject([]){|m, kv| m + ['NOT'] + Search.new(nil, Hash[*kv]).to_imap_search_keys}
    end

    def general_to_imap_search_key(key, value)
      value.is_a?(Negated) ? ['NOT', key, value.value] : [key, value]
    end

    def boolean_to_imap_search_key(key, value)
      if value
        [key]
      else
        ['NOT', key]
      end
    end

    def negating?
      negate = @negate
      @negate = false
      negate
    end

    def message_ids
      imap_client.imap.search(to_imap_search_keys)
    end
    alias_method :all, :message_ids

    private

    def initialize(imap_client = nil, criteria = nil)
      @criteria = criteria || {}
      @imap_client = imap_client
    end
  end
end
