# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSla do
  let(:customer) { User.create!(email: 'c@helpdesk.local', password: 'password123', role: :customer) }

  describe '.reminder_wait' do
    it 'returns longer waits for lower urgency priorities' do
      expect(described_class.reminder_wait(:urgent)).to be < described_class.reminder_wait(:low)
    end

    it 'defaults unknown priorities to 24 hours' do
      expect(described_class.reminder_wait(:unknown)).to eq(24.hours)
    end
  end

  describe '.due_at' do
    it 'is created_at plus the priority reminder wait' do
      ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :high, created_at: Time.current)

      expect(described_class.due_at(ticket)).to be_within(1.second).of(ticket.created_at + 8.hours)
    end
  end

  describe '.state' do
    it 'is :ok when well within the SLA window' do
      ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :low, created_at: Time.current)

      expect(described_class.state(ticket)).to eq(:ok)
    end

    it 'is :at_risk once inside the last 25% of the SLA window' do
      ticket = Ticket.create!(
        title: 'VPN', customer: customer, priority: :high, created_at: 7.hours.ago
      )

      expect(described_class.state(ticket)).to eq(:at_risk)
    end

    it 'is :breached once past the due time' do
      ticket = Ticket.create!(
        title: 'VPN', customer: customer, priority: :urgent, created_at: 5.hours.ago
      )

      expect(described_class.state(ticket)).to eq(:breached)
    end
  end
end
