# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Me', type: :request do
  let!(:admin) do
    User.create!(
      email: 'admin@helpdesk.local',
      password: 'password123',
      role: :admin
    )
  end

  describe 'GET /api/v1/me' do
    it 'returns the current user when logged in' do
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }
      get '/api/v1/me'

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        'user' => {
          'id' => admin.id,
          'email' => admin.email,
          'role' => { 'code' => 'admin', 'label' => 'Admin' },
          'disabled' => false
        }
      )
    end

    it 'returns unauthorized when not logged in' do
      get '/api/v1/me'

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Unauthorized')
    end

    it 'returns Spanish labels when locale=es' do
      post '/api/v1/session', params: { email: admin.email, password: 'password123' }
      get '/api/v1/me', params: { locale: 'es' }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig('user', 'role', 'label')).to eq('Administrador')
    end
  end

  describe 'GET /api/v1/me/export' do
    let!(:customer) do
      User.create!(email: 'export@helpdesk.local', password: 'password123', role: :customer)
    end
    let!(:ticket) { Ticket.create!(title: 'GDPR ticket', customer: customer) }

    it 'returns a GDPR export payload for the current user' do
      login_as(customer)
      get '/api/v1/me/export'

      expect(response).to have_http_status(:ok)
      export = JSON.parse(response.body)['export']
      expect(export['format']).to eq('helpdesk-gdpr-export-v1')
      expect(export['tickets'].size).to eq(1)
    end
  end

  describe 'PATCH /api/v1/me' do
    let!(:customer) do
      User.create!(email: 'reset@helpdesk.local', password: 'password123', role: :customer)
    end

    it 'updates the password when the current password is correct' do
      login_as(customer)
      patch '/api/v1/me', params: { current_password: 'password123', new_password: 'newpassword456' }

      expect(response).to have_http_status(:ok)
      expect(customer.reload.authenticate('newpassword456')).to eq(customer)
    end

    it 'rejects the update when the current password is wrong' do
      login_as(customer)
      patch '/api/v1/me', params: { current_password: 'wrongpassword', new_password: 'newpassword456' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(customer.reload.authenticate('password123')).to eq(customer)
    end
  end

  describe 'DELETE /api/v1/me' do
    let!(:customer) do
      User.create!(email: 'delete@helpdesk.local', password: 'password123', role: :customer)
    end

    it 'deletes the account and clears the session' do
      login_as(customer)
      delete '/api/v1/me'

      expect(response).to have_http_status(:no_content)
      expect(User.find_by(id: customer.id)).to be_nil

      get '/api/v1/me'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
