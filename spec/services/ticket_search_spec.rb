# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSearch do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:admin) { User.create!(email: 'admin@helpdesk.local', password: 'password123', role: :admin) }
  let!(:other_customer) { User.create!(email: 'other@helpdesk.local', password: 'password123', role: :customer) }

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
  end
end
