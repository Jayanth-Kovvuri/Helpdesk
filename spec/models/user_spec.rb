# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) do
    described_class.new(
      email: 'agent@helpdesk.local',
      password: 'password123',
      role: :customer
    )
  end

  it 'is valid with required attributes' do
    expect(user.valid?).to be(true)
  end

  it 'requires a unique email (case-insensitive)' do
    user.save!
    duplicate = described_class.new(
      email: 'AGENT@helpdesk.local',
      password: 'password123',
      role: :customer
    )
    expect(duplicate).not_to be_valid
  end

  it 'authenticates with the correct password' do
    user.save!
    expect(user.authenticate('password123')).to eq(user)
  end

  describe 'disabling' do
    it 'is not disabled by default' do
      user.save!
      expect(user.disabled?).to be(false)
    end

    it 'becomes disabled after #disable!' do
      user.save!
      user.disable!
      expect(user.disabled?).to be(true)
    end

    it 'becomes enabled again after #enable!' do
      user.save!
      user.disable!
      user.enable!
      expect(user.disabled?).to be(false)
    end
  end

  describe 'roles' do
    it 'defaults to customer' do
      new_user = described_class.create!(
        email: 'new@helpdesk.local',
        password: 'password123'
      )
      expect(new_user).to be_customer
    end

    it 'supports admin' do
      user.role = :admin
      user.save!
      expect(user).to be_admin
    end
  end
end
