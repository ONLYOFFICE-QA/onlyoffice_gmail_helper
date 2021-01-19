# frozen_string_literal: true

module OnlyofficeGmailHelper
  # Class for storing mail account data
  class MailAccount
    # @return [String] user name
    attr_accessor :username
    alias login username
    # @return [String] user password
    attr_accessor :password

    def initialize(user, pass)
      @username = user
      @password = pass
    end
  end
end
