# Imap/Search.rb
# Imap::Search

# Usage:
# 1. Imap::Search.new.not.subject('Payday Loans').answered.from('noreply@example.com').all
# 2. Imap::Search.new({from: 'noreply@example.com', answered: true})

# Notes:
# 1. List of search keys taken from RFC-3501 (INTERNET MESSAGE ACCESS PROTOCOL - VERSION 4rev1), http://tools.ietf.org/html/rfc3501.

class Imap
  class Search

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
      define_method boolean_search_key do |value = true|
        criteria.merge!(boolean_search_key.to_sym => value)
      end
    end

    GENERAL_SEARCH_KEYS.each do |general_search_key|
      define_method general_search_key do |value|
        criteria.merge!(general_search_key.to_sym => value)
      end
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
        when general_operator?(key)
          m << general_to_imap_search_key(key, value)
        when boolean_operator?(key)
          m << boolean_to_imap_search_key(key, value)
        end
      end.flatten
    end

    def general_to_imap_search_key(key, value)
      [key, value]
    end

    def boolean_to_imap_search_key(key, value)
      if value
        [key]
      else
        ['NOT', key]
      end
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
