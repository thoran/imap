# imap

A Ruby wrapper around Net::IMAP with a hash-based search interface and messages which answer questions rather than handing back structs.

## Features

- Hash-based search criteria, including OR, NOT and repeated keys
- Message accessors for dates, flags, size, addresses and attachments
- RFC 2047 decoding, which Net::IMAP does not do
- Attachment filenames read out of the BODYSTRUCTURE, which IMAP cannot search upon
- One fetch for a whole set of messages rather than one per attribute
- BODY.PEEK throughout, so that reading a message does not mark it read
- No Rails dependency - works anywhere
- Zero external dependencies beyond net-imap

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'imap'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install imap
```

The gem is published under both `imap` and `imap.rb`. They are the same code; install one.

## Usage

### Connecting

```ruby
require 'imap'

imap_client = Imap.setup(
  server: 'imap.example.com',
  username: 'someone@example.com',
  password: 'bigsecret',
  mailbox: 'INBOX' # optional/default
)
```

`Imap.setup` raises `Imap::LoginFailed` where the server rejects the password, or where only one of the username and the password is given. `Imap#login` answers true or false for a caller which would rather handle it itself.

`Imap#mailboxes` lists every mailbox which can be selected:

```ruby
imap_client.mailboxes                   # => ['INBOX', 'INBOX.Archive', ...]
imap_client.mailbox = 'INBOX.Archive'
```

### Searching

Criteria are a hash, keyed by the IMAP search keys in lower case:

```ruby
messages = imap_client.search(
  from: 'noreply@example.com',
  subject: 'Payday Loans',
  since: '18-Dec-2025',
  seen: false
)
```

`or:` takes a list of criteria hashes. IMAP's OR takes two keys, so three or more nest for you:

```ruby
imap_client.search(or: [{from: 'a@x'}, {to: 'b@y'}, {cc: 'c@z'}])
```

`not:` negates each key it carries:

```ruby
imap_client.search(not: {subject: 'Payday'})
```

`all_of:` is how one key carries several terms, a hash holding it only once:

```ruby
imap_client.search(all_of: [{text: 'invoice'}, {text: 'overdue'}])
```

`header:` takes the field and the value:

```ruby
imap_client.search(header: ['List-Id', 'ruby-talk'])
```

An unrecognised key raises `Imap::Search::UnknownSearchKey` rather than widening the search silently.

Where the search keys are built elsewhere, `Imap::Message.for` does the fetch on its own:

```ruby
Imap::Message.for(imap_client, imap_client.imap.search(['ALL']))
```

### Messages

A search fetches UID, FLAGS, INTERNALDATE, RFC822.SIZE, ENVELOPE and BODYSTRUCTURE for the whole set in one command, so none of these costs a round trip:

```ruby
messages.each do |message|
  message.uid
  message.flags                     # => [:Seen]
  message.seen?
  message.size                      # bytes
  message.received_at               # Time, from INTERNALDATE
  message.sent_at                   # Time, from the Date header
  message.subject                   # encoded words decoded
  message.from                      # => 'Café <billing@example.com>'
  message.from_address              # => 'billing@example.com'
  message.from_domain               # => 'example.com'
  message.to                        # => ['user@example.com']
  message.cc
  message.attachment?
  message.attachment_filenames      # => ['résumé.pdf']
end
```

The body is fetched only when it is asked for:

```ruby
message.body                        # BODY[TEXT], undecoded
message.source                      # the whole message, headers and all
message.urls                        # the URLs found in the body
message.mark_as_read
```

`#body` is the raw text part. Choosing a part out of a multipart message and undoing its transfer encoding is MIME work rather than IMAP work, so hand `#source` to the `mail` gem where that is wanted:

```ruby
mail = Mail.read_from_string(message.source)
```

### Decoding

`Imap::Message.decode` reads RFC 2047 encoded words, which headers carry wherever a subject or a name is not ASCII:

```ruby
Imap::Message.decode('=?UTF-8?B?UsOpc3Vtw6k=?=')   # => 'Résumé'
```

### Extending

`Imap::Message.search` and `.for` build with `new`, so a subclass is handed back its own kind:

```ruby
class Message < Imap::Message
  def body
    @body ||= Mail.read_from_string(source).text_part.decoded
  end
end

Message.for(imap_client, message_ids).first.class   # => Message
```

### Finishing

```ruby
imap_client.bye
```

## Contributing

1. Fork it (https://github.com/thoran/imap/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request

## License

MIT
