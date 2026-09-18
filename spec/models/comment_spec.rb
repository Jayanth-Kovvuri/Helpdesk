# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:customer) { User.create!(email: 'c@helpdesk.local', name: 'c@helpdesk.local', password: 'password123', role: :customer) }
  let(:ticket) { Ticket.create!(title: 'Issue', customer: customer) }

  it 'is valid with body and associations' do
    comment = described_class.new(body: 'Please help', ticket: ticket, user: customer)
    expect(comment.valid?).to be(true)
  end

  it 'strips HTML from body' do
    comment = described_class.create!(
      body: '<script>alert(1)</script>Hello',
      ticket: ticket,
      user: customer
    )
    expect(comment.body).to eq('Hello')
  end

  describe '#manageable_by?' do
    let(:admin) { User.create!(email: 'a@helpdesk.local', name: 'a@helpdesk.local', password: 'password123', role: :admin) }
    let(:comment) { described_class.create!(body: 'Note', ticket: ticket, user: customer) }

    it 'allows the author' do
      expect(comment.manageable_by?(customer)).to be(true)
    end

    it 'allows admin' do
      expect(comment.manageable_by?(admin)).to be(true)
    end
  end
end
