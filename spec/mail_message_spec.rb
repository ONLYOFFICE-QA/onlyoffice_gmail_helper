# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MailMessage' do
  it 'check compare of two same mail messages' do
    message1 = OnlyofficeGmailHelper::MailMessage.new('test', 'test')
    message2 = OnlyofficeGmailHelper::MailMessage.new('test', 'test')
    expect(message1).to eq(message2)
  end
end
