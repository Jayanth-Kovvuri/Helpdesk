# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSearch do
  let!(:matching_user) do
    User.create!(email: 'alice@helpdesk.local', name: 'Alice Smith', password: 'password123', role: :customer)
  end
  let!(:other_user) do
    User.create!(email: 'bob@helpdesk.local', name: 'Bob Jones', password: 'password123', role: :admin)
  end

  describe '.call' do
    it 'returns all users for queries shorter than the minimum length' do
      results = described_class.call(query: 'a')

      expect(results.map(&:id)).to contain_exactly(matching_user.id, other_user.id)
    end

    it 'finds users by name or email via SQL fallback' do
      results = described_class.call(query: 'alice')

      expect(results.map(&:id)).to eq([matching_user.id])
    end

    it 'does not match role text when searching by admin keyword' do
      results = described_class.call(query: 'admin')

      expect(results).to be_empty
    end

    it 'limits results to admins when role filter is set' do
      results = described_class.call(query: 'bob', role: 'admin')

      expect(results.map(&:id)).to eq([other_user.id])
    end
  end
end
