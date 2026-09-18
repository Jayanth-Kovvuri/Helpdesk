# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSearch do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:admin) { User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin) }
  let!(:other_customer) { User.create!(email: 'other@helpdesk.local', name: 'other@helpdesk.local', password: 'password123', role: :customer) }

  let!(:matching_ticket) do
    Ticket.create!(title: 'Printer jam', description: 'Paper stuck', customer: customer)
  end
  let!(:other_ticket) do
    Ticket.create!(title: 'VPN outage', description: 'Remote access', customer: other_customer)
  end

  describe '.call' do
    it 'returns no results for queries shorter than the minimum length' do
      results = described_class.call(user: admin, query: 'p')
      expect(results).to be_empty
    end

    it 'scopes SQL fallback results for customers' do
      results = described_class.call(user: customer, query: 'printer')

      expect(results.map(&:id)).to eq([matching_ticket.id])
    end

    it 'returns all matching tickets for admins via SQL fallback' do
      results = described_class.call(user: admin, query: 'pr')

      expect(results.map(&:id)).to contain_exactly(matching_ticket.id)
    end

    it 'limits SQL fallback results to raised tickets for the customer' do
      Ticket.create!(
        title: 'Other customer printer',
        description: 'Needs fix',
        customer: other_customer,
        assignee: admin
      )

      results = described_class.call(user: customer, query: 'printer', filter: 'raised')

      expect(results.map(&:id)).to eq([matching_ticket.id])
    end

    it 'limits SQL fallback results to assigned tickets for the admin' do
      assigned_ticket = Ticket.create!(
        title: 'Admin assigned printer',
        description: 'Needs fix',
        customer: other_customer,
        assignee: admin
      )

      results = described_class.call(user: admin, query: 'printer', filter: 'assigned')

      expect(results.map(&:id)).to eq([assigned_ticket.id])
    end
  end
end
