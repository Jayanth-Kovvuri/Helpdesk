# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  let!(:user) do
    User.create!(
      email: 'customer@helpdesk.local',
      name: 'Customer User',
      password: 'password123',
      role: :customer
    )
  end

  describe 'POST /api/v1/session' do
    it 'creates a session with valid credentials' do
      post '/api/v1/session', params: { email: user.email, password: 'password123' }

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to eq(
        'user' => {
          'id' => user.id,
          'email' => user.email,
          'name' => user.name,
          'role' => { 'code' => 'customer', 'label' => 'Customer' },
          'disabled' => false
        }
      )
    end

    it 'rejects invalid credentials' do
      post '/api/v1/session', params: { email: user.email, password: 'wrong' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Invalid email or password')
    end

    it 'rejects a disabled account even with correct credentials' do
      user.disable!

      post '/api/v1/session', params: { email: user.email, password: 'password123' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'This account has been disabled')
    end

    it 'does not reveal disabled status for a wrong password' do
      user.disable!

      post '/api/v1/session', params: { email: user.email, password: 'wrong' }

      expect(JSON.parse(response.body)).to eq('error' => 'Invalid email or password')
    end

    it 'persists the session for JSON login like the React client' do
      with_forgery_protection do
        post '/api/v1/session',
             params: { email: user.email, password: 'password123' }.to_json,
             headers: { 'CONTENT_TYPE' => 'application/json' }

        expect(response).to have_http_status(:created)

        get '/api/v1/me'
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).dig('user', 'email')).to eq(user.email)
      end
    end
  end

  describe 'an active session for a user disabled mid-session' do
    it 'is logged out on the next request' do
      post '/api/v1/session', params: { email: user.email, password: 'password123' }
      user.disable!

      get '/api/v1/me'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/session' do
    it 'logs out an authenticated user' do
      post '/api/v1/session', params: { email: user.email, password: 'password123' }
      delete '/api/v1/session'

      expect(response).to have_http_status(:no_content)

      get '/api/v1/me'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
