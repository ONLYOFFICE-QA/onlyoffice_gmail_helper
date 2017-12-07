module OnlyofficeGmailHelper
  class MailAccount
    attr_accessor :username
    alias login username
    attr_accessor :password

    def initialize(user, pass)
      @username = user
      @password = pass
    end
  end
end
