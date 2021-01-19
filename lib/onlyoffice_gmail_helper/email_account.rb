require_relative 'email_account/mail_account'

module OnlyofficeGmailHelper
  class EmailAccount
    def self.read_defaults
      return read_env_defaults if read_env_defaults

      yaml = YAML.load_file("#{Dir.home}/.gem-onlyoffice_gmail_helper/config.yml")
      { user: yaml['user'], password: yaml['password'] }
    rescue Errno::ENOENT
      raise Errno::ENOENT, 'No config found. Please create ~/.gem-onlyoffice_gmail_helper/config.yml'
    end

    # Read keys from env variables
    def self.read_env_defaults
      return false unless ENV['GMAIL_USER'] && ENV['GMAIL_PASSWORD']

      { user: ENV['GMAIL_USER'], password: ENV['GMAIL_PASSWORD'] }
    end

    GMAIL_DEFAULT = MailAccount.new(read_defaults[:user], read_defaults[:password])
  end
end
