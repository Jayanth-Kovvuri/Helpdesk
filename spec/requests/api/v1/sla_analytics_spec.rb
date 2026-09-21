# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::SlaAnalytics', type: :request do
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end

  describe 'GET /api/v1/sla_analytics' do
    it 'returns analytics for admins' do
      login_as(admin)
      get '/api/v1/sla_analytics'

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include('period', 'summary', 'by_priority', 'by_assignee')
    end

    it 'forbids customers' do
      login_as(customer)
      get '/api/v1/sla_analytics'

      expect(response).to have_http_status(:forbidden)
    end
  end
end
