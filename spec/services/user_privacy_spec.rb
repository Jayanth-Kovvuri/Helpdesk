# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPrivacy do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:ticket) { Ticket.create!(title: 'Export me', description: 'Private data', customer: customer) }

  describe '.destroy_account!' do
    it 'removes the user and their tickets' do
      described_class.destroy_account!(customer)

      expect(User.find_by(id: customer.id)).to be_nil
      expect(Ticket.find_by(id: ticket.id)).to be_nil
    end
  end
end
