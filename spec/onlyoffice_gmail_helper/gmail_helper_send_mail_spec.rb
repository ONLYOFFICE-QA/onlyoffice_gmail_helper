# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OnlyofficeGmailHelper::Gmail_helper, '#send_mail' do
  let(:gmail) { described_class.new }

  it 'Mail can be sended to yourself' do
    uniq_data = "spec-gmail-helper-#{SecureRandom.uuid}"
    title = "title-#{uniq_data}"
    body = "body-#{uniq_data}"
    gmail.send_mail(gmail.user, title, body)
    expect(gmail.get_body_message_by_title(title, title)).to eq("#{body}\n")
  end
end
