module OnlyofficeGmailHelper
  # Class for working with single message
  class MailMessage
    attr_accessor :title
    attr_accessor :content
    attr_accessor :reply_to
    attr_accessor :date
    attr_accessor :tags

    def initialize(title, content = nil, reply_to = nil, date = nil, tags = nil)
      @title = title
      @content = content
      @reply_to = reply_to
      unless @content.nil? && !content.is_a?(Regexp)
        begin
          @content.delete!("\n")
        rescue StandardError
          Exception
        end
        begin
          @content.gsub!("\r\n", '')
        rescue StandardError
          Exception
        end
        begin
          @content.gsub!("\n\n", '')
        rescue StandardError
          Exception
        end
        begin
          @content.gsub!('&#8220;', '"')
        rescue StandardError
          Exception
        end
        begin
          @content.gsub!('&#8221;', '"')
        rescue StandardError
          Exception
        end
        begin
          @content.tr!("\r", ' ')
        rescue StandardError
          Exception
        end
      end
      @date = date
      @tags = tags
    end

    def ==(other)
      compare_title = (title.delete("\n") == other.title.delete("\n"))
      compare_body = true
      if (StaticDataTeamLab.check_email_body if defined?(StaticDataTeamLab.check_email_body)) && compare_title
        compare_body = false if (other.content =~ content).nonzero?
      end
      compare_title && compare_body
    end
  end
end
