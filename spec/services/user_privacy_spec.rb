# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPrivacy do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:ticket) { Ticket.create!(title: 'Export me', description: 'Private data', customer: customer) }
  let!(:comment) { Comment.create!(body: 'My note', ticket: ticket, user: customer) }

  describe '.export' do
    it 'includes profile, tickets, and authored comments' do
      data = described_class.export(customer)

      expect(data[:format]).to eq('helpdesk-gdpr-export-v1')
      expect(data[:user][:email]).to eq(customer.email)
      expect(data[:tickets].size).to eq(1)
      expect(data[:tickets].first[:title]).to eq('Export me')
      expect(data[:tickets].first[:comments].size).to eq(1)
      expect(data[:comments_authored].size).to eq(1)
    end
  end

  describe '.destroy_account!' do
    it 'removes the user and their tickets' do
      described_class.destroy_account!(customer)

      expect(User.find_by(id: customer.id)).to be_nil
      expect(Ticket.find_by(id: ticket.id)).to be_nil
    end
  end
end
