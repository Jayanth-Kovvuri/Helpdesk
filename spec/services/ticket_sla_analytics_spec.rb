# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSlaAnalytics do
  let(:customer) { User.create!(email: 'c@helpdesk.local', name: 'c@helpdesk.local', password: 'password123', role: :customer) }

  describe '.report' do
    it 'summarizes closed tickets in the period by resolve time and SLA compliance' do
      Ticket.create!(
        title: 'Fast', customer: customer, priority: :high,
        status: :resolved, created_at: 5.days.ago, updated_at: 2.days.ago
      )
      Ticket.create!(
        title: 'Also fast', customer: customer, priority: :high,
        status: :closed, created_at: 4.days.ago, updated_at: 2.days.ago
      )

      report = described_class.report

      expect(report[:summary][:closed_count]).to eq(2)
      expect(report[:summary][:sla_compliance_rate]).to eq(1.0)
      expect(report[:summary][:sla_breach_escalations_count]).to eq(0)
      expect(report[:by_priority].find { |row| row[:code] == 'high' }[:closed_count]).to eq(2)
    end

    it 'counts SLA breach escalations when resolve time exceeds the priority deadline' do
      Ticket.create!(
        title: 'Late', customer: customer, priority: :urgent,
        status: :resolved, created_at: 10.days.ago, updated_at: 1.day.ago
      )

      report = described_class.report

      expect(report[:summary][:sla_breach_escalations_count]).to eq(1)
      expect(report[:summary][:sla_compliance_rate]).to eq(0.0)
    end
  end
end
