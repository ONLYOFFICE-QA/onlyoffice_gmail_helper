# frozen_string_literal: true

require 'gmail'
require 'onlyoffice_logger_helper'
require 'onlyoffice_gmail_helper/email_account'
require 'onlyoffice_gmail_helper/mail_message'
require 'onlyoffice_gmail_helper/version'

# Override object class
class Object
  # @return [Date] format date for imap
  def to_imap_date
    Date.parse(to_s).strftime('%d-%b-%Y')
  end
end

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

    # Refresh connection data
    # @return [nil]
    def refresh
      logout
      @gmail = Gmail.new(@user, @password)
    end

    # Wait until unread message exists
    # @param [String] title message to wait
    # @param [Integer] timeout to wait
    # @param [Integer] period sleep between tries
    # @return [MailMessage] found message
    def wait_until_unread_message(title,
                                  timeout = @timeout_for_mail, period = 60)
      counter = 0
      message_found = false
      while counter < timeout && !message_found
        @gmail.inbox.emails.each do |current_mail|
          next unless current_mail.subject.include?(title)

          message = MailMessage.new(current_mail.subject,
                                    current_mail.html_part.body)
          return message
        end
        sleep period
        refresh
      end
      raise "Message with title: #{title} not found for #{timeout * 60} seconds"
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

    # @return [Array<Message>] list of underad messages
    def get_unread_messages
      refresh
      array_of_mail = []
      mailbox.emails(:unread).reverse_each do |current_mail|
        current_title = current_mail.message.subject
        current_subject = begin
          current_mail.html_part.body.decoded
                      .force_encoding('utf-8').encode('UTF-8')
        rescue StandardError
          Exception
        end
        current_mail.mark(:unread)
        reply_to = current_mail.reply_to[0] unless current_mail.reply_to == []
        array_of_mail << MailMessage.new(current_title,
                                         current_subject,
                                         reply_to)
      end
      array_of_mail
    end

    # Check unread messages for message
    # @param [String] mail_message to find
    # @return [Boolean] result
    def check_unread_messages_for_message(mail_message)
      messages = get_unread_messages
      timer = 0
      message_found = false
      while timer < @timeout_for_mail && message_found == false
        messages.each do |current_unread_mail|
          # p current_unread_mail
          if current_unread_mail == mail_message
            delete_messages(current_unread_mail)
            return true
          end
        end
        messages = get_unread_messages
        timer += 1
      end
      false
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

    # Delete message with portal address
    # @param [String] message title to delete
    # @param [String] current_portal_full_name to delete
    # @return [nil]
    def delete_message_with_portal_address(message, current_portal_full_name)
      300.times do
        messages_array = mailbox.emails(:unread, search: current_portal_full_name.to_s)
        messages_array.each do |current_mail|
          if message.title == current_mail.message.subject
            current_mail.delete!
            return true
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

    # @param [String] contain_string message to delete
    # @return [nil]
    def delete_all_message_contains(contain_string)
      OnlyofficeLoggerHelper.log("Messages containing #{contain_string} will be deleted")
      messages_array = mailbox.emails(:unread, search: contain_string)
      messages_array.each(&:delete!)
    end

    # Reply to mail
    # @param [String] mail_to_reply
    # @param [String] reply_body to do
    # @return [nil]
    def reply_mail(mail_to_reply, reply_body)
      messages = get_unread_messages
      timer = 0
      message_found = false
      while timer < @timeout_for_mail && message_found == false
        messages.each do |current_unread_mail|
          next unless current_unread_mail == mail_to_reply

          email = @gmail.compose do
            to("#{current_unread_mail.reply_to.mailbox}@#{current_unread_mail.reply_to.host}".to_s)
            subject "Re: #{current_unread_mail.title}"
            body reply_body
          end
          email.deliver!
          delete_messages(current_unread_mail)
          return true
        end
        messages = get_unread_messages
        timer += 1
      end
      false
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

    # Send notification
    # @param [String] email to send
    # @param [String] test_name - name of test
    # @param [String] error - error to send
    # @param [String] mail_title to send
    # @return [nil]
    def send_notification(email, test_name, error, mail_title = 'Teamlab Daily Check')
      body = "Fail in #{test_name}\n" \
             "Error text: \n\t #{error}"
      send_mail(email, mail_title, body)
    end

    # @return [Integer] count message in inbox
    def mail_inbox_count
      count = @gmail.inbox.emails.count
      OnlyofficeLoggerHelper.log("#{count} mails in inbox of #{@user}")
      count
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

    # Delete all mail from sender
    # @param [String] string messanger
    # @return [nil]
    def delete_from_sender(string)
      mailbox.emails(from: string).each(&:delete!)
    end

    # Mark all messages as unread
    # @return [nil]
    def mark_all_unread
      mailbox.emails.each do |current_mail|
        current_mail.mark(:unread)
      end
    end

    # Send mail test result
    # @param [String] mail to send
    # @param [String] title to send
    # @param [Array<String>] array_results test data
    # @return [nil]
    def send_mail_test_result(mail, title, array_results)
      body = ''
      array_results.each do |current_result|
        current_result[1] = 'OK' if current_result[1].nil?
        body = "#{body}#{current_result[0]}\t#{current_result[1]}\n"
      end

      if mail.is_a?(Array)
        mail.each do |current_mail_user|
          email = @gmail.compose do
            to current_mail_user
            subject title
            body body
          end
          email.deliver!
        end
      else
        email = @gmail.compose do
          to mail
          subject title
          body body
        end
        email.deliver!
      end
    end

    # If not returning nested levels please change content of file
    # +/home/#{user}/.rvm/gems/#{gemset}/gems/gmail-0.4.0/lib/gmail/labels.rb+
    # to content of that file: https://github.com/jgrevich/gmail/blob/6ed88950bd631696aeb1bc4b9133b03d1ae4055f/lib/gmail/labels.rb
    # @return [Array<String>] list of all labels
    def get_labels
      @gmail.labels.all
    end

    # Get list of unread mails with tags
    # @return [Array<MailMessage>] result
    def get_unread_mails_with_tags
      refresh
      array_of_mail = []
      mailbox.emails(:unread).each do |current_mail|
        current_title = current_mail.message.subject
        current_subject = begin
          current_mail.html_part.body.decoded.force_encoding('utf-8').encode('UTF-8')
        rescue StandardError
          Exception
        end
        current_mail.mark(:unread)
        reply_to = current_mail.reply_to[0] unless current_mail.reply_to.nil?
        current_tag = current_mail
        array_of_mail << MailMessage.new(current_title, current_subject, reply_to, current_tag)
      end
      array_of_mail
    end

    # Get body by email subject
    # @param [String] subject to get
    # @param [String] portal_name to filter
    # @return [String] body
    def get_body_by_subject_email(subject, portal_name)
      p 'get_body_by_subject_email'
      300.times do |current|
        p "current time: #{current}"
        messages_array = mailbox.emails(:unread, search: portal_name.to_s)
        messages_array.each do |current_mail|
          current_subject = current_mail.message.subject
          p "current_subject: #{current_subject}"
          if message_found?(current_subject, subject)
            body_text = current_mail.message.text_part.body.decoded.force_encoding('utf-8').encode('UTF-8').gsub(/\s+/, ' ').strip
            return body_text
          end
        end
      end
      nil
    end

    private

    def message_found?(given, needed)
      given.to_s.upcase.include? needed.to_s.upcase
    end
  end
end
