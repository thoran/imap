# imap

A Ruby wrapper around Net::IMAP with an elegant DSL for searching, reading, and managing email.

## Features

- Clean, hash-based search interface
- Intuitive message accessors
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

## Usage
```ruby
require 'imap'

# Connect and authenticate
imap_client = Imap.setup(
  server: 'imap.thoran.com',
  username: 'code@thoran.com',
  password: 'bigsecret',
  mailbox: 'INBOX' # optional/default
)

messages = imap_client.search(
  from: 'noreply@example.com',
  subject: 'Payday Loans',
  since: '18-DEC-2025',
  seen: false
)

# Access message details
messages.each do |message|
  puts message.subject
  puts message.from
  puts message.to
  puts message.body
  puts message.urls # Extracted URLs from body
end

# Mark messages as read
messages.first.mark_as_read

# Clean up
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
