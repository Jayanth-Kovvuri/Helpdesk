# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::SlaDashboard', type: :request do
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end

  describe 'GET /api/v1/sla_dashboard' do
    it 'returns SLA counts for an admin' do
      Ticket.create!(title: 'Breached', customer: customer, priority: :urgent, created_at: 3.days.ago)
      login_as(admin)

      get '/api/v1/sla_dashboard'

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['counts']).to eq('breached' => 1, 'at_risk' => 0, 'ok' => 0)
      expect(body['breached_tickets'].first['title']).to eq('Breached')
    end

    it 'rejects a non-admin user' do
      login_as(customer)

      get '/api/v1/sla_dashboard'

      expect(response).to have_http_status(:forbidden)
    end

    it 'requires login' do
      get '/api/v1/sla_dashboard'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
