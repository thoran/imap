# test/test_helper.rb

require 'minitest/autorun'
require 'minitest/mock'
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

  attr_reader :list_called
  attr_reader :fetched_attrs
  attr_reader :fetch_count

  def fetch(message_ids, attrs)
    @fetched_attrs = attrs
    @fetch_count = (@fetch_count || 0) + 1
    Array(message_ids).collect do |message_id|
      Net::IMAP::FetchData.new(message_id, mock_fetch_attrs(message_id, attrs))
    end
  end

  def list(reference, pattern)
    @list_called = true
    [
      OpenStruct.new(attr: [:Hasnochildren], name: 'INBOX'),
      OpenStruct.new(attr: [:Noselect, :Haschildren], name: 'Archive'),
      OpenStruct.new(attr: [:Hasnochildren], name: 'Archive/2026')
    ]
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
      when 'BODY[TEXT]', 'BODY.PEEK[TEXT]'
        result['BODY[TEXT]'] = "Mock body for message #{message_id}"
      when 'BODY[]', 'BODY.PEEK[]'
        result['BODY[]'] = "Subject: Mock Subject #{message_id}\r\n\r\nMock body for message #{message_id}"
      when 'UID'
        result['UID'] = 1000 + message_id
      when 'FLAGS'
        result['FLAGS'] = message_id == 2 ? [:Seen] : []
      when 'INTERNALDATE'
        result['INTERNALDATE'] = '17-Sep-2026 09:15:00 +1000'
      when 'RFC822.SIZE'
        result['RFC822.SIZE'] = 2048
      when 'BODYSTRUCTURE'
        result['BODYSTRUCTURE'] = mock_bodystructure(message_id)
      when 'ENVELOPE'
        result['ENVELOPE'] = mock_envelope(message_id)
      end
    end
    result
  end

  # Message 2 carries the encoded words, message 99 the empty envelope.
  def mock_envelope(message_id)
    OpenStruct.new(
      date: 'Thu, 17 Sep 2026 09:05:00 +1000',
      subject: message_id == 2 ? '=?UTF-8?B?UsOpc3Vtw6kgZm9yIHJldmlldw==?=' : "Mock Subject #{message_id}",
      from: [
        message_id == 2 ?
          OpenStruct.new(name: '=?UTF-8?Q?Caf=C3=A9?=', mailbox: 'sender', host: 'Example.COM') :
          OpenStruct.new(mailbox: 'sender', host: 'example.com')
      ],
      to: message_id == 99 ? nil : [OpenStruct.new(mailbox: 'user', host: 'example.com')],
      cc: message_id == 99 ? nil : [OpenStruct.new(mailbox: 'copied', host: 'example.com')]
    )
  end

  # Message 1 names its attachment in the disposition, message 2 in the content
  # type's NAME and in an encoded word, the rest carry none.
  def mock_bodystructure(message_id)
    text = OpenStruct.new(media_type: 'TEXT', subtype: 'PLAIN', param: nil, disposition: nil)
    case message_id
    when 1
      attachment = OpenStruct.new(
        media_type: 'APPLICATION',
        subtype: 'PDF',
        param: {'NAME' => 'ignored.pdf'},
        disposition: OpenStruct.new(dsp_type: 'ATTACHMENT', param: {'FILENAME' => 'invoice.pdf'})
      )
      OpenStruct.new(media_type: 'MULTIPART', subtype: 'MIXED', parts: [text, attachment])
    when 2
      attachment = OpenStruct.new(
        media_type: 'APPLICATION',
        subtype: 'PDF',
        param: {'NAME' => '=?UTF-8?B?csOpc3Vtw6kucGRm?='},
        disposition: nil
      )
      OpenStruct.new(media_type: 'MULTIPART', subtype: 'MIXED', parts: [text, attachment])
    else
      text
    end
  end
end
