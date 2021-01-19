# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MailMessage' do
  it 'check compare of two same mail messages' do
    expect(OnlyofficeGmailHelper::MailMessage.new('test', 'test'))
      .to eq(OnlyofficeGmailHelper::MailMessage.new('test', 'test'))
  end
end
