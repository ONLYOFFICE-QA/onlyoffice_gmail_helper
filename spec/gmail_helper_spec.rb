require 'spec_helper'

RSpec.describe 'gmail helper' do
  let(:gmail) { OnlyofficeGmailHelper::Gmail_helper.new }
  let(:test_message) { OnlyofficeGmailHelper::MailMessage.new('test', 'test') }

  it 'login to gmail' do
    expect(gmail.mailbox.name).to eq('[Gmail]/All Mail')
  end

  it 'check_messages_for_message_with_portal_address non-existing' do
    expect(gmail.check_messages_for_message_with_portal_address(test_message, 'portal_name', times: 1)).to be_falsey
  end

  it 'check_messages_for_message_with_portal_address non-existing with newline in portal' do
    expect(gmail.check_messages_for_message_with_portal_address(test_message, "nonexisting_stuff\nnonexisting_stuff", times: 1)).to be_falsey
  end
end
