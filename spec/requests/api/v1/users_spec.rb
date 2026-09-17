# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end

  describe 'POST /api/v1/users' do
    it 'allows an admin to create a new account with a role and password' do
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }

      post '/api/v1/users', params: { email: 'agent@helpdesk.local', password: 'password123', role: 'admin' }

      expect(response).to have_http_status(:created)
      expect(User.find_by(email: 'agent@helpdesk.local')).to be_admin
    end

    it 'rejects creation from a non-admin user' do
      post '/api/v1/session', params: { email: customer.email, password: 'password123' }

      post '/api/v1/users', params: { email: 'agent@helpdesk.local', password: 'password123', role: 'admin' }

      expect(response).to have_http_status(:forbidden)
      expect(User.find_by(email: 'agent@helpdesk.local')).to be_nil
    end

    it 'rejects creation when not logged in' do
      post '/api/v1/users', params: { email: 'agent@helpdesk.local', password: 'password123', role: 'admin' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns validation errors for invalid input' do
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }

      post '/api/v1/users', params: { email: 'not-an-email', password: 'short', role: 'admin' }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/users' do
    it 'lists users for an admin' do
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }

      get '/api/v1/users'

      expect(response).to have_http_status(:ok)
      emails = JSON.parse(response.body)['users'].pluck('email')
      expect(emails).to include(admin.email, customer.email)
    end

    it 'rejects listing from a non-admin user' do
      post '/api/v1/session', params: { email: customer.email, password: 'password123' }

      get '/api/v1/users'

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /api/v1/users/:id' do
    it 'allows an admin to disable another account' do
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }

      patch "/api/v1/users/#{customer.id}", params: { disabled: true }

      expect(response).to have_http_status(:ok)
      expect(customer.reload.disabled?).to be(true)
    end

    it 'allows an admin to re-enable a disabled account' do
      customer.disable!
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }

      patch "/api/v1/users/#{customer.id}", params: { disabled: false }

      expect(response).to have_http_status(:ok)
      expect(customer.reload.disabled?).to be(false)
    end

    it 'prevents an admin from disabling their own account' do
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }

      patch "/api/v1/users/#{admin.id}", params: { disabled: true }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(admin.reload.disabled?).to be(false)
    end

    it 'rejects the update from a non-admin user' do
      post '/api/v1/session', params: { email: customer.email, password: 'password123' }

      patch "/api/v1/users/#{admin.id}", params: { disabled: true }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
