require 'spec_helper'

RSpec.describe 'gmail helper' do
  it 'login to gmail' do
    skip('Google blocking travis location')
    expect(OnlyofficeGmailHelper::Gmail_helper.new.mailbox.name).to eq('[Gmail]/All Mail')
  end
end
