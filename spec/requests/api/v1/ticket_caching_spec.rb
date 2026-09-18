# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Ticket response caching', type: :request do
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end
  let!(:ticket) do
    Ticket.create!(title: 'Cached title', description: 'Details', customer: customer)
  end

  def json
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/tickets' do
    it 'serves repeated index responses from Rails.cache' do
      login_as(customer)
      get '/api/v1/tickets'
      first_body = response.body

      expect(Rails.cache.exist?(TicketResponseCache.index_key(customer))).to be(true)

      get '/api/v1/tickets'
      expect(response.body).to eq(first_body)
    end

    it 'refreshes index responses after a ticket update changes the cache key' do
      login_as(customer)
      get '/api/v1/tickets'
      expect(json['tickets'].first['title']).to eq('Cached title')

      ticket.update!(title: 'Updated title')
      get '/api/v1/tickets'

      expect(json['tickets'].first['title']).to eq('Updated title')
    end
  end

  describe 'GET /api/v1/tickets search cache keys' do
    it 'uses separate cache entries per list filter' do
      login_as(customer)
      get '/api/v1/tickets', params: { q: 'cached', filter: 'raised' }
      raised_key = TicketResponseCache.search_key(customer, 'cached', filter: 'raised')
      assigned_key = TicketResponseCache.search_key(customer, 'cached', filter: 'assigned')

      expect(raised_key).not_to eq(assigned_key)
      expect(Rails.cache.exist?(raised_key)).to be(true)
    end
  end

  describe 'GET /api/v1/tickets/:id' do
    it 'refreshes show responses when the ticket is updated' do
      login_as(customer)
      get "/api/v1/tickets/#{ticket.id}"
      expect(json['ticket']['title']).to eq('Cached title')

      ticket.update!(title: 'Show cache bust')
      get "/api/v1/tickets/#{ticket.id}"

      expect(json['ticket']['title']).to eq('Show cache bust')
    end
  end
end
