# frozen_string_literal: true

require 'gmail'
require 'onlyoffice_logger_helper'
require 'onlyoffice_gmail_helper/email_account'
require 'onlyoffice_gmail_helper/mail_message'
require 'onlyoffice_gmail_helper/version'

# Monkey patch IMAP to fix https://bugs.ruby-lang.org/issues/14750
# TODO: Remove after release of fix as stable version
module Net
  # Imap main class
  class IMAP
    # override bugged method
    alias send_literal_bug_14750 send_literal

    # Override for but 14750
    def send_literal(str, tag = nil)
      if RUBY_VERSION.start_with?('2.5', '2.6')
        send_literal_bug_14750(str, tag)
      else
        send_literal_bug_14750(str)
      end
    end
  end
end

# Helper module for GMail
module OnlyofficeGmailHelper
  # Main class of gem
  class Gmail_helper
    # @return [Gmail] gmail object
    attr_accessor :gmail
    # @return [String] user name
    attr_accessor :user
    # @return [String] user password
    attr_accessor :password
    # @return [Integer] default timeout for operation
    attr_accessor :timeout_for_mail
    # @return [String] default label
    attr_accessor :label

    def initialize(user = EmailAccount::GMAIL_DEFAULT.login, password = EmailAccount::GMAIL_DEFAULT.password, timeout_for_mail = 10, label = nil)
      @user = user
      @password = password
      @gmail = Gmail.new(user, password)
      @imap = @gmail.instance_variable_get(:@imap)
      @timeout_for_mail = timeout_for_mail
      @label = label
    end

    # Select mailbox
    # @return [nil]
    def mailbox
      if @label
        if @label == :inbox
          @gmail.inbox
        else
          @gmail.mailbox(@label)
        end
      else
        @gmail.mailbox('[Gmail]/All Mail')
      end
    end

    # Perform logout
    # @return [nil]
    def logout
      @gmail.logout
      @imap.disconnect until @imap.disconnected?
    rescue StandardError
      Exception
    end

    # Get mail body by title
    # @param [String] portal_address to filter
    # @param [String] subject to find
    # @param [Integer] time to wait
    # @param [Boolean] delete if needed
    # @return [MailMessage] found message
    def get_body_message_by_title(portal_address, subject, time = 300, delete = true)
      start_time = Time.now
      flags = block_given? ? yield : { search: portal_address.to_s }
      while Time.now - start_time < time
        messages_array = mailbox.emails(:unread, flags)
        messages_array.each do |current_mail|
          next unless message_found?(current_mail.message.subject, subject)

          body = begin
            current_mail.html_part.body.decoded.force_encoding('utf-8').encode('UTF-8')
          rescue StandardError
            Exception
          end
          current_mail.delete! if delete
          return body
        end
      end
      nil
    end

    # Check message for message with portal
    # @param [String] message title
    # @param [String] current_portal_full_name name
    # @param [Integer] times to wait
    # @return [Boolean] is messag found
    def check_messages_for_message_with_portal_address(message, current_portal_full_name, times: 300)
      times.times do
        messages_array = mailbox.emails(:unread, search: current_portal_full_name.to_s)
        messages_array.each do |current_mail|
          next unless message_found?(current_mail.message.subject, message.title)

          OnlyofficeLoggerHelper.log('Email successfully found and removed')
          current_mail.delete!
          return true
        end
        sleep 1
      end
      false
    end

    # Delete specific message
    # @param [String] message title to delete
    # @return [nil]
    def delete_messages(message)
      message = [message] unless message.is_a?(Array)
      message.each do |message_to_delete|
        mailbox.emails(:unread).each do |current_mail|
          if message_to_delete.title == current_mail.message.subject
            current_mail.delete!
          else
            begin
              current_mail.mark(:unread)
            rescue StandardError
              Exception
            end
          end
        end
      end
    end

    # Delete all messsages
    # @return [nil]
    def delete_all_messages
      OnlyofficeLoggerHelper.log("Start deleting all messaged on mail: #{@user}")
      mailbox.emails.each(&:delete!)
      @gmail.logout
      OnlyofficeLoggerHelper.log("Finished deleting all messaged on mail: #{@user}")
    end

    # Send mail
    # @param [String] email to send
    # @param [String] title to send
    # @param [String] body to send
    # @param [String] attachment to send
    # @return [nil]
    def send_mail(email, title, body, attachment = nil)
      email = @gmail.compose do
        to email
        subject title
        body body
        add_file attachment unless attachment.nil?
      end
      email.deliver!
      OnlyofficeLoggerHelper.log("send_mail(#{email}, #{title}, #{body}, #{attachment})")
    end

    # List all mail in label with date
    # @param [String] string label
    # @param [Date] date_start to find
    # @param [Date] date_end to find
    # @param [String] to whom message send
    # @return [Array<MailMessage>] list of results
    def mail_in_label_with_date(string, date_start, date_end, to = nil)
      array_of_mail = []
      @gmail.mailbox(string).emails(after: date_start, before: date_end, to: to).each do |current_mail|
        current_title = current_mail.message.subject
        current_subject = begin
          current_mail.html_part.body.decoded
                      .force_encoding('utf-8').encode('UTF-8')
        rescue StandardError
          Exception
        end
        reply_to = current_mail.reply_to[0] unless current_mail.reply_to.nil?
        array_of_mail << MailMessage.new(current_title,
                                         current_subject,
                                         reply_to, Time.parse(current_mail.date))
      end
      array_of_mail
    end

    private

    def message_found?(given, needed)
      given.to_s.upcase.include? needed.to_s.upcase
    end
  end
end
