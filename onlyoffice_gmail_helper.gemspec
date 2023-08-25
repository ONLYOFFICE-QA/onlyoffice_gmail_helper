# frozen_string_literal: true

require_relative 'lib/onlyoffice_gmail_helper/name'
require_relative 'lib/onlyoffice_gmail_helper/version'

Gem::Specification.new do |s|
  s.name = OnlyofficeGmailHelper::NAME
  s.version = OnlyofficeGmailHelper::VERSION
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.7'
  s.authors = ['ONLYOFFICE', 'Pavel Lobashov']
  s.email = %w[shockwavenn@gmail.com]
  s.summary = 'ONLYOFFICE Helper Gem for GMail'
  s.description = 'ONLYOFFICE Helper Gem for GMail. Used in QA'
  s.homepage = "https://github.com/ONLYOFFICE-QA/#{s.name}"
  s.metadata = {
    'bug_tracker_uri' => "#{s.homepage}/issues",
    'changelog_uri' => "#{s.homepage}/blob/master/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{s.name}",
    'homepage_uri' => s.homepage,
    'source_code_uri' => s.homepage,
    'rubygems_mfa_required' => 'true'
  }
  s.files = Dir['lib/**/*']
  s.license = 'AGPL-3.0'
  s.add_runtime_dependency('gmail', '~> 0.6')
  s.add_runtime_dependency('net-imap', '~> 0')
  s.add_runtime_dependency('net-smtp', '~> 0')
  s.add_runtime_dependency('onlyoffice_logger_helper', '~> 1')
end
