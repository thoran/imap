# ImapClient/Search.rb
# ImapClient::Search

# Usage:
# ImapClient::Search.new.not.subject('Payday Loans').answered.from('no_reply@example.com').all

# Notes: 
# 1. List of search keys taken from RFC-3501 (INTERNET MESSAGE ACCESS PROTOCOL - VERSION 4rev1), http://tools.ietf.org/html/rfc3501.

require 'String/include_patternQ'
require 'String/to_regexp'

class ImapClient
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
    LOGICAL_SEARCH_KEYS = %w{NOT OR}
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
    #BINARY_SEARCH_KEYS = BOOLEAN_SEARCH_KEYS + GENERAL_SEARCH_KEYS

    GENERAL_SEARCH_KEYS.each do |general_search_key|
      define_method general_search_key do |value|
        criteria.merge!(general_search_key.to_sym value)
      end
    end

    BOOLEAN_SEARCH_KEYS.each do |boolean_search_key|
      define_method boolean_search_key do |value = true|
        criteria.merge!(boolean_search_key.to_sym value)
      end
    end

    attr_accessor :criteria
    attr_accessor :imap_client

    def initialize(criteria = nil, imap_client = nil)
      @criteria = criteria || {}
      @imap_client = imap_client
    end

    def general_operator?(search_key)
      GENERAL_SEARCH_KEYS.include?(search_key)
    end

    def boolean_operator?(search_key)
      BOOLEAN_SEARCH_KEYS.include?(search_key)
    end

    def logical_operator?(search_key)
      logical_search_key_regexes = LOGICAL_SEARCH_KEYS.collect{|e| e.to_regex}
      search_key.include_pattern?(*logical_search_key_regexes)
    end

    def to_imap_search_keys
      criteria.inject([]) do |m, kv|
        key, value = kv.first.to_s.upcase, kv.last
        case
        when general_operator?(key)
          m << general_to_imap_search_key(key, value)
        when boolean_operator?(key)
          m << boolean_to_imap_search_key(key)
        when logical_operator?(key)
          m << logical_to_imap_search_key(key, value)
        end
      end.flatten
    end

    def general_to_imap_search_key(key, value)
      [key, value]
    end

    def boolean_to_imap_search_key(key)
      key
    end

    def logical_to_imap_search_key(key, value)
      case key
      when /NOT/
        negated_key = key.split('_').obliterate('NOT')
        ['NOT', negated_key, value]
      when /OR/
        orred_key = key.split('_').obliterate('OR')
        ['OR', orred_key, value]
      end
    end

    def message_ids
      imap_client.imap.search(to_imap_search_keys)
    end
    alias_method :all, :message_ids

  end
end
