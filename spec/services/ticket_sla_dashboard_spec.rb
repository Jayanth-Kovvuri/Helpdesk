# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSlaDashboard do
  let(:customer) { User.create!(email: 'c@helpdesk.local', name: 'c@helpdesk.local', password: 'password123', role: :customer) }

  describe '.summary' do
    it 'counts active tickets by SLA state' do
      Ticket.create!(title: 'Fresh', customer: customer, priority: :low, created_at: Time.current)
      Ticket.create!(title: 'At risk', customer: customer, priority: :high, created_at: 2.5.days.ago)
      Ticket.create!(title: 'Breached', customer: customer, priority: :urgent, created_at: 2.5.days.ago)

      summary = described_class.summary

      expect(summary[:counts]).to eq(breached: 1, at_risk: 1, ok: 1)
    end

    it 'filters by ticket created_at when from and to are given' do
      in_range = Ticket.create!(title: 'In range', customer: customer, priority: :low, created_at: 5.days.ago)
      Ticket.create!(title: 'Too old', customer: customer, priority: :low, created_at: 20.days.ago)

      from = 10.days.ago.to_date.to_s
      to = Time.current.to_date.to_s
      summary = described_class.summary(from: from, to: to)

      ids = summary.values_at(:breached_tickets, :at_risk_tickets, :ok_tickets).flatten.pluck(:id)
      expect(ids).to eq([in_range.id])
      expect(summary[:counts].values.sum).to eq(1)
    end

    it 'ignores a single date param and shows all active tickets' do
      Ticket.create!(title: 'Active', customer: customer, priority: :low, created_at: Time.current)

      summary = described_class.summary(from: 10.days.ago.to_date.to_s, to: nil)

      expect(summary[:counts].values.sum).to eq(1)
    end

    it 'ignores resolved and closed tickets' do
      Ticket.create!(
        title: 'Old but resolved', customer: customer, priority: :urgent, created_at: 2.5.days.ago,
        status: :resolved
      )

      summary = described_class.summary

      expect(summary[:counts]).to eq(breached: 0, at_risk: 0, ok: 0)
    end

    it 'removes a ticket from the dashboard after it is closed' do
      ticket = Ticket.create!(
        title: 'Will close', customer: customer, priority: :urgent, created_at: 2.5.days.ago
      )

      expect(described_class.summary[:counts][:breached]).to eq(1)

      ticket.update!(status: :closed)

      expect(described_class.summary[:counts][:breached]).to eq(0)
    end

    it 'lists breached tickets ordered by how overdue they are' do
      very_late = Ticket.create!(title: 'Very late', customer: customer, priority: :urgent, created_at: 4.days.ago)
      just_late = Ticket.create!(title: 'Just late', customer: customer, priority: :urgent, created_at: 2.1.days.ago)

      summary = described_class.summary

      expect(summary[:breached_tickets].pluck(:id)).to eq([very_late.id, just_late.id])
    end

    it 'caches the result until a ticket is created or updated' do
      Ticket.create!(title: 'Fresh', customer: customer, priority: :low, created_at: Time.current)
      first = described_class.summary
      second = described_class.summary

      expect(second).to eq(first)

      Ticket.create!(title: 'Breached', customer: customer, priority: :urgent, created_at: 2.5.days.ago)
      third = described_class.summary

      expect(third).not_to eq(first)
      expect(third[:counts][:breached]).to eq(1)
    end
  end
end
