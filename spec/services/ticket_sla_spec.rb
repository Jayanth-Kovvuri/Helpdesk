# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSla do
  let(:customer) { User.create!(email: 'c@helpdesk.local', name: 'c@helpdesk.local', password: 'password123', role: :customer) }

  describe '.sla_config' do
    it 'returns correct config for each priority' do
      expect(described_class.sla_config(:urgent)).to eq({ sla_days: 2, at_risk_days: 1 })
      expect(described_class.sla_config(:high)).to eq({ sla_days: 3, at_risk_days: 2 })
      expect(described_class.sla_config(:medium)).to eq({ sla_days: 5, at_risk_days: 3 })
      expect(described_class.sla_config(:low)).to eq({ sla_days: 7, at_risk_days: 5 })
    end

    it 'defaults unknown priorities to medium' do
      expect(described_class.sla_config(:unknown)).to eq(described_class.sla_config(:medium))
    end
  end

  describe '.sla_days' do
    it 'returns SLA days for each priority' do
      expect(described_class.sla_days(:urgent)).to eq(2)
      expect(described_class.sla_days(:high)).to eq(3)
      expect(described_class.sla_days(:medium)).to eq(5)
      expect(described_class.sla_days(:low)).to eq(7)
    end
  end

  describe '.due_at' do
    it 'is created_at plus the priority SLA days' do
      ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :high, created_at: Time.current)

      expect(described_class.due_at(ticket)).to be_within(1.second).of(ticket.created_at + 3.days)
    end
  end

  describe '.state' do
    it 'is :ok when within at_risk threshold' do
      ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :high, created_at: 1.day.ago)
      expect(described_class.state(ticket)).to eq(:ok)
    end

    it 'is :at_risk when between at_risk and SLA thresholds' do
      ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :high, created_at: 2.5.days.ago)
      expect(described_class.state(ticket)).to eq(:at_risk)
    end

    it 'is :breached when past SLA threshold' do
      ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :high, created_at: 4.days.ago)
      expect(described_class.state(ticket)).to eq(:breached)
    end

    context 'for urgent priority' do
      it 'is :ok for 0.5 days' do
        ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :urgent, created_at: 0.5.days.ago)
        expect(described_class.state(ticket)).to eq(:ok)
      end

      it 'is :at_risk for 1.5 days' do
        ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :urgent, created_at: 1.5.days.ago)
        expect(described_class.state(ticket)).to eq(:at_risk)
      end

      it 'is :breached for 3 days' do
        ticket = Ticket.create!(title: 'VPN', customer: customer, priority: :urgent, created_at: 3.days.ago)
        expect(described_class.state(ticket)).to eq(:breached)
      end
    end
  end
end
