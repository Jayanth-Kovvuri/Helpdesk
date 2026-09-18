# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketResponseCache do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:ticket) { Ticket.create!(title: 'Cache me', description: 'Body', customer: customer) }

  describe '.index_key' do
    it 'changes when a visible ticket is updated' do
      key_before = described_class.index_key(customer)
      ticket.update!(title: 'Changed')
      key_after = described_class.index_key(customer)

      expect(key_after).not_to eq(key_before)
    end
  end

  describe '.fetch_index' do
    it 'returns cached JSON without re-running the block' do
      first = described_class.fetch_index(customer) { '{"tickets":[]}' }
      second = described_class.fetch_index(customer) { raise 'cache miss' }

      expect(second).to eq(first)
    end
  end
end
