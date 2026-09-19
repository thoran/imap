# imap.rb.gemspec

require_relative './lib/Imap/VERSION'

class Gem::Specification
  def dependencies=(gems)
    gems.each{|gem| add_dependency(*gem)}
  end

  def development_dependencies=(gems)
    gems.each{|gem| add_development_dependency(*gem)}
  end
end

Gem::Specification.new do |spec|
  spec.name = 'imap.rb'

  spec.version = Imap::VERSION

  spec.summary = "IMAP for Ruby made easy."
  spec.description = "A Ruby wrapper around Net::IMAP with an elegant DSL for searching, reading, and managing email."

  spec.author = 'thoran'
  spec.email = 'code@thoran.com'
  spec.homepage = 'https://github.com/thoran/imap'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 2.7'

  spec.dependencies = [
    ['net-imap', '>= 0.4.5']
  ]

  spec.development_dependencies = [
    'minitest',
    'minitest-mock',
    'rake'
  ]

  spec.files = [
    'imap.rb.gemspec',
    Dir['lib/**/*.rb'],
    Dir['test/**/*.rb'],
    'CHANGELOG',
    'Gemfile',
    'Rakefile',
    'LICENSE',
    'README.md',
  ].flatten
  spec.require_paths = ['lib']

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/thoran/imap/issues",
    "changelog_uri" => "https://github.com/thoran/imap/blob/master/CHANGELOG",
    "source_code_uri" => "https://github.com/thoran/imap",
    "documentation_uri" => "https://github.com/thoran/imap/blob/master/README.md"
  }
end
