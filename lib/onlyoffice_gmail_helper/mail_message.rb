# frozen_string_literal: true

module OnlyofficeGmailHelper
  # Class for working with single message
  class MailMessage
    # @return [String] mail title
    attr_accessor :title
    # @return [String] mail content
    attr_accessor :content
    # @return [String] reply to field
    attr_accessor :reply_to
    # @return [String] date field
    attr_accessor :date
    # @return [String] tags field
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

    # Compare message with other
    # @param [MailMessage] other to compare
    # @return [Boolean] result
    def ==(other)
      compare_title = (title.delete("\n") == other.title.delete("\n"))
      compare_body = true
      compare_body = false if (StaticDataTeamLab.check_email_body if defined?(StaticDataTeamLab.check_email_body)) && compare_title && (other.content =~ content).nonzero?
      compare_title && compare_body
    end
  end
end
