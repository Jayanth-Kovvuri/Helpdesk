# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSlaDashboard do
  let(:customer) { User.create!(email: 'c@helpdesk.local', password: 'password123', role: :customer) }

  describe '.summary' do
    it 'counts active tickets by SLA state' do
      Ticket.create!(title: 'Fresh', customer: customer, priority: :low, created_at: Time.current)
      Ticket.create!(title: 'At risk', customer: customer, priority: :high, created_at: 7.hours.ago)
      Ticket.create!(title: 'Breached', customer: customer, priority: :urgent, created_at: 5.hours.ago)

      summary = described_class.summary

      expect(summary[:counts]).to eq(breached: 1, at_risk: 1, ok: 1)
    end

    it 'ignores resolved and closed tickets' do
      Ticket.create!(
        title: 'Old but resolved', customer: customer, priority: :urgent, created_at: 5.hours.ago,
        status: :resolved
      )

      summary = described_class.summary

      expect(summary[:counts]).to eq(breached: 0, at_risk: 0, ok: 0)
    end

    it 'lists breached tickets ordered by how overdue they are' do
      very_late = Ticket.create!(title: 'Very late', customer: customer, priority: :urgent, created_at: 10.hours.ago)
      just_late = Ticket.create!(title: 'Just late', customer: customer, priority: :urgent, created_at: 4.1.hours.ago)

      summary = described_class.summary

      expect(summary[:breached_tickets].pluck(:id)).to eq([very_late.id, just_late.id])
    end

    it 'caches the result for repeated calls' do
      Ticket.create!(title: 'Fresh', customer: customer, priority: :low, created_at: Time.current)
      first = described_class.summary

      Ticket.create!(title: 'Breached', customer: customer, priority: :urgent, created_at: 5.hours.ago)
      second = described_class.summary

      expect(second).to eq(first)
    end
  end
end
