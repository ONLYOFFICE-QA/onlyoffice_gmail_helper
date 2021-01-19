# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Release gem '
task :release_github_rubygems do
  Rake::Task['release'].invoke
  gem_name = "pkg/#{OnlyofficeGmailHelper::NAME}-"\
              "#{OnlyofficeGmailHelper::VERSION}.gem"
  sh('gem push --key github '\
   '--host https://rubygems.pkg.github.com/ONLYOFFICE-QA '\
   "#{gem_name}")
end
