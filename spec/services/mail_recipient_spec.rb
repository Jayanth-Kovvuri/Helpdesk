# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MailRecipient do
  describe '.delivery_address' do
    around do |example|
      @previous = ENV['NOTIFICATION_EMAIL']
      example.run
    ensure
      if @previous.nil?
        ENV.delete('NOTIFICATION_EMAIL')
      else
        ENV['NOTIFICATION_EMAIL'] = @previous
      end
    end

    it 'returns the override for routed notification types' do
      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      expect(described_class.delivery_address(:ticket_assigned, 'user@helpdesk.local')).to eq('notify@example.com')
      expect(described_class.delivery_address(:sla_breach, 'admin@helpdesk.local')).to eq('notify@example.com')
    end

    it 'returns the default when override is unset' do
      ENV.delete('NOTIFICATION_EMAIL')
      expect(described_class.delivery_address(:ticket_assigned, 'user@helpdesk.local')).to eq('user@helpdesk.local')
    end

    it 'returns the default for non-routed types even when override is set' do
      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      expect(described_class.delivery_address(:ticket_created, 'user@helpdesk.local')).to eq('user@helpdesk.local')
    end
  end
end
