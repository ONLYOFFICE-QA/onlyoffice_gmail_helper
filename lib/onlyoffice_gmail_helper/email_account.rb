# frozen_string_literal: true

require_relative 'email_account/mail_account'

module OnlyofficeGmailHelper
  # Class for storing default mail accounts
  class EmailAccount
    # Read default values for account
    # @return [Hash] result
    def self.read_defaults
      return read_env_defaults if read_env_defaults

      yaml = YAML.load_file("#{Dir.home}/.gem-onlyoffice_gmail_helper/config.yml")
      { user: yaml['user'], password: yaml['password'] }
    rescue Errno::ENOENT
      raise Errno::ENOENT, 'No config found. Please create ~/.gem-onlyoffice_gmail_helper/config.yml'
    end

    # Read keys from env variables
    # @return [Hash]
    def self.read_env_defaults
      return false unless ENV.key?('GMAIL_USER') && ENV.key?('GMAIL_PASSWORD')

      # rubocop:disable Style/FetchEnvVar
      { user: ENV['GMAIL_USER'], password: ENV['GMAIL_PASSWORD'] }
      # rubocop:enable Style/FetchEnvVar
    end

    # @return [MailAccount] default account
    GMAIL_DEFAULT = MailAccount.new(read_defaults[:user], read_defaults[:password])
  end
end
