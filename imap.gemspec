# imap.gemspec

require_relative './lib/Imap/VERSION'

Gem::Specification.new do |spec|
  spec.name = 'imap'

  spec.version = Imap::VERSION
  spec.date = '2025-12-20'

  spec.summary = "IMAP for Ruby made easy."
  spec.description = "A Ruby wrapper around Net::IMAP with an elegant DSL for searching, reading, and managing email."

  spec.author = 'thoran'
  spec.email = 'code@thoran.com'
  spec.homepage = 'https://github.com/thoran/imap'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'net-imap', "~> 0.4"

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'

  spec.files = [
    'imap.gemspec',
    Dir['lib/**/*.rb'],
    'README.md',
    Dir['test/**/*.rb']
  ].flatten
  spec.require_paths = ['lib']
end
