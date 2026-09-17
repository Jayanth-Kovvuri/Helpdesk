# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tag, type: :model do
  it 'normalizes the name to lowercase and trimmed' do
    tag = described_class.create!(name: '  Network  ')
    expect(tag.name).to eq('network')
  end

  it 'rejects duplicate names case-insensitively' do
    described_class.create!(name: 'network')
    duplicate = described_class.new(name: 'NETWORK')

    expect(duplicate).not_to be_valid
  end
end
