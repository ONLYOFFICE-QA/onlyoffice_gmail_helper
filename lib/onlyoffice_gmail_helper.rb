# frozen_string_literal: true

require 'gmail'
require 'onlyoffice_logger_helper'
require 'onlyoffice_gmail_helper/email_account'
require 'onlyoffice_gmail_helper/mail_message'
require 'onlyoffice_gmail_helper/version'

class Object
  def to_imap_date
    Date.parse(to_s).strftime('%d-%b-%Y')
  end
end

# Monkey patch IMAP to fix https://bugs.ruby-lang.org/issues/14750
# TODO: Remove after release of fix as stable version
module Net
  class IMAP
    alias send_literal_bug_14750 send_literal

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
  class Gmail_helper
    attr_accessor :gmail
    attr_accessor :user
    attr_accessor :password
    attr_accessor :timeout_for_mail
    attr_accessor :label

    def initialize(user = EmailAccount::GMAIL_DEFAULT.login, password = EmailAccount::GMAIL_DEFAULT.password, timeout_for_mail = 10, label = nil)
      @user = user
      @password = password
      @gmail = Gmail.new(user, password)
      @imap = @gmail.instance_variable_get(:@imap)
      @timeout_for_mail = timeout_for_mail
      @label = label
    end

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

    def logout
      @gmail.logout
      @imap.disconnect until @imap.disconnected?
    rescue StandardError
      Exception
    end

    def refresh
      logout
      @gmail = Gmail.new(@user, @password)
    end

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

    def get_body_message_by_title_from_mail(current_portal_full, title1 = 'Welcome to ONLYOFFICE™ Portal!', title2 = 'Добро пожаловать на портал TeamLab!', delete = true, _to_mail = nil)
      mail_not_found = true
      attempt = 0
      while mail_not_found
        messages_array = mailbox.emails(:unread, search: current_portal_full.to_s)
        messages_array.each do |current_mail|
          current_subject = current_mail.message.subject
          a = current_subject.include? title1
          b = current_subject.include? title2
          if a || b
            current_subject = begin
              current_mail.html_part.body.decoded.force_encoding('utf-8').encode('UTF-8')
            rescue StandardError
              Exception
            end
            current_mail.delete! if current_subject == 'Welcome to Your TeamLab Portal!'
            if current_subject.include? current_portal_full
              current_mail.delete! if delete
              return current_subject
            end
          else
            raise "Message with title: #{title1} not found after #{attempt} attempt" if attempt == 10

            sleep 10
            attempt += 1
            current_mail.delete! if delete
          end
        end
      end
    end

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

    # received mail in format "Thu, 23 Jan 2014 15:34:57 +0400". Day of week may\may not be present
    def get_current_date(date_str)
      data_arr = date_str.split.reverse
      { day: data_arr[4].to_i, hour: data_arr[1].split(':')[0].to_i, minute: data_arr[1].split(':')[1].to_i }
    end

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

    def delete_all_messages
      OnlyofficeLoggerHelper.log("Start deleting all messaged on mail: #{@user}")
      mailbox.emails.each(&:delete!)
      @gmail.logout
      OnlyofficeLoggerHelper.log("Finished deleting all messaged on mail: #{@user}")
    end

    def archive_inbox
      OnlyofficeLoggerHelper.log("Start achieving  all messaged in inbox on mail: #{@user}")
      @gmail.inbox.emails.each(&:archive!) if mail_inbox_count.nonzero?
      OnlyofficeLoggerHelper.log("Finished achieving  all messaged in inbox on mail: #{@user}")
    end

    def delete_all_message_contains(contain_string)
      OnlyofficeLoggerHelper.log("Messages containing #{contain_string} will be deleted")
      messages_array = mailbox.emails(:unread, search: contain_string)
      messages_array.each(&:delete!)
    end

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

    def send_notification(email, test_name, error, mail_title = 'Teamlab Daily Check')
      body = "Fail in #{test_name}\n" \
             "Error text: \n\t #{error}"
      send_mail(email, mail_title, body)
    end

    def mail_inbox_count
      count = @gmail.inbox.emails.count
      OnlyofficeLoggerHelper.log("#{count} mails in inbox of #{@user}")
      count
    end

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

    def delete_from_sender(string)
      mailbox.emails(from: string).each(&:delete!)
    end

    def mark_all_unread
      mailbox.emails.each do |current_mail|
        current_mail.mark(:unread)
      end
    end

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
    def get_labels
      @gmail.labels.all
    end

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
