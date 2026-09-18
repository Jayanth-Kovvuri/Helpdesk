# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ticket, type: :model do
  let(:customer) { User.create!(email: 'c@helpdesk.local', name: 'c@helpdesk.local', password: 'password123', role: :customer) }
  let(:admin) { User.create!(email: 'a@helpdesk.local', name: 'a@helpdesk.local', password: 'password123', role: :admin) }

  it 'is valid with required attributes' do
    ticket = described_class.new(
      title: 'Login issue',
      description: 'Cannot reset password',
      customer: customer
    )
    expect(ticket.valid?).to be(true)
  end

  it 'requires assignee to be an admin' do
    other_customer = User.create!(email: 'c2@helpdesk.local', name: 'c2@helpdesk.local', password: 'password123', role: :customer)
    ticket = described_class.new(title: 'Test', customer: customer, assignee: other_customer)
    expect(ticket).not_to be_valid
  end

  describe '#search_data' do
    it 'includes attached tag names' do
      ticket = described_class.create!(title: 'VPN', customer: customer)
      ticket.tags << Tag.create!(name: 'network')

      expect(ticket.search_data[:tag_names]).to eq('network')
    end
  end

  describe '.visible_to' do
    let!(:customer_ticket) { described_class.create!(title: 'Mine', customer: customer) }
    let!(:other_ticket) do
      other = User.create!(email: 'other@helpdesk.local', name: 'other@helpdesk.local', password: 'password123', role: :customer)
      described_class.create!(title: 'Theirs', customer: other)
    end

    it 'returns all tickets for admin' do
      expect(described_class.visible_to(admin)).to contain_exactly(customer_ticket, other_ticket)
    end

    it 'returns only own tickets for customer' do
      expect(described_class.visible_to(customer)).to contain_exactly(customer_ticket)
    end
  end
end
