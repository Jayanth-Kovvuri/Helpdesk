# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Ticket search', type: :request do
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:other_customer) do
    User.create!(email: 'other@helpdesk.local', name: 'other@helpdesk.local', password: 'password123', role: :customer)
  end

  let!(:customer_ticket) do
    Ticket.create!(title: 'Email sync', description: 'Outlook issues', customer: customer)
  end
  let!(:other_ticket) do
    Ticket.create!(title: 'Email server', description: 'SMTP errors', customer: other_customer)
  end

  def json
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/tickets/search' do
    it 'requires login' do
      get '/api/v1/tickets/search', params: { q: 'email' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'requires the q parameter' do
      login_as(customer)
      get '/api/v1/tickets/search'

      expect(response).to have_http_status(:bad_request)
      expect(json['error']).to include('q')
    end

    it 'returns only visible tickets for a customer' do
      login_as(customer)
      get '/api/v1/tickets/search', params: { q: 'email' }

      expect(response).to have_http_status(:ok)
      ids = json['tickets'].map { |t| t['id'] }
      expect(ids).to eq([customer_ticket.id])
    end

    it 'returns matching tickets across customers for an admin' do
      login_as(admin)
      get '/api/v1/tickets/search', params: { q: 'email' }

      expect(response).to have_http_status(:ok)
      ids = json['tickets'].map { |t| t['id'] }
      expect(ids).to contain_exactly(customer_ticket.id, other_ticket.id)
    end
  end
end
