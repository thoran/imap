# test/test_helper.rb

require 'minitest/autorun'
require 'minitest/spec'
require 'ostruct'
require_relative '../lib/imap'

class MockIMAP
  attr_reader :login_called
  attr_reader :logout_called
  attr_reader :search_called
  attr_reader :search_criteria
  attr_reader :select_called
  attr_reader :selected_mailbox

  def login(username, password)
    @login_called = true
    @username = username
    @password = password
  end

  def select(mailbox)
    @select_called = true
    @selected_mailbox = mailbox
  end

  def search(criteria)
    @search_called = true
    @search_criteria = criteria
    [1, 2, 3]
  end

  def fetch(message_id, attrs)
    [OpenStruct.new(attr: mock_fetch_attrs(message_id, attrs))]
  end

  def store(message_id, flags, values); end

  def logout
    @logout_called = true
  end

  def disconnect; end

  private

  def initialize(server, ssl:)
    @server = server
    @ssl = ssl
    @login_called = false
    @select_called = false
    @search_called = false
    @logout_called = false
  end

  def mock_fetch_attrs(message_id, attrs)
    result = {}
    attrs.each do |attr|
      case attr
      when 'BODY[TEXT]'
        result['BODY[TEXT]'] = "Mock body for message #{message_id}"
      when 'BODY[HEADER.FIELDS (SUBJECT)]'
        result['BODY[HEADER.FIELDS (SUBJECT)]'] = "Subject: Mock Subject #{message_id}\r\n"
      when 'BODY[HEADER.FIELDS (FROM)]'
        result['BODY[HEADER.FIELDS (FROM)]'] = "From: sender@example.com\r\n"
      when 'ENVELOPE'
        result['ENVELOPE'] = OpenStruct.new(
          to: [OpenStruct.new(mailbox: 'user', host: 'example.com')]
        )
      end
    end
    result
  end
end
