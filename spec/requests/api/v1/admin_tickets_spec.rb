# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::AdminTickets', type: :request do
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end
  let!(:other_customer) do
    User.create!(email: 'other@helpdesk.local', password: 'password123', role: :customer)
  end

  def json
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/admin/tickets' do
    it 'rejects a non-admin user' do
      login_as(customer)

      get '/api/v1/admin/tickets'

      expect(response).to have_http_status(:forbidden)
    end

    it 'requires login' do
      get '/api/v1/admin/tickets'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists tickets across all customers for an admin' do
      Ticket.create!(title: 'Mine', customer: customer)
      Ticket.create!(title: 'Theirs', customer: other_customer)
      login_as(admin)

      get '/api/v1/admin/tickets'

      expect(response).to have_http_status(:ok)
      expect(json['tickets'].pluck('title')).to contain_exactly('Mine', 'Theirs')
    end

    it 'paginates results' do
      15.times { |i| Ticket.create!(title: "Ticket #{i}", customer: customer) }
      login_as(admin)

      get '/api/v1/admin/tickets', params: { per_page: 10, page: 2 }

      expect(json['tickets'].size).to eq(5)
      expect(json['meta']).to eq(
        'page' => 2, 'per_page' => 10, 'total_count' => 15, 'total_pages' => 2
      )
    end

    it 'filters by status' do
      Ticket.create!(title: 'Open one', customer: customer, status: :open)
      Ticket.create!(title: 'Closed one', customer: customer, status: :closed)
      login_as(admin)

      get '/api/v1/admin/tickets', params: { status: 'closed' }

      expect(json['tickets'].pluck('title')).to eq(['Closed one'])
    end

    it 'filters by priority' do
      Ticket.create!(title: 'Urgent one', customer: customer, priority: :urgent)
      Ticket.create!(title: 'Low one', customer: customer, priority: :low)
      login_as(admin)

      get '/api/v1/admin/tickets', params: { priority: 'urgent' }

      expect(json['tickets'].pluck('title')).to eq(['Urgent one'])
    end

    it 'filters by assignee_id' do
      Ticket.create!(title: 'Assigned', customer: customer, assignee: admin)
      Ticket.create!(title: 'Unassigned', customer: customer)
      login_as(admin)

      get '/api/v1/admin/tickets', params: { assignee_id: admin.id }

      expect(json['tickets'].pluck('title')).to eq(['Assigned'])
    end

    it 'filters for unassigned tickets' do
      Ticket.create!(title: 'Assigned', customer: customer, assignee: admin)
      Ticket.create!(title: 'Unassigned', customer: customer)
      login_as(admin)

      get '/api/v1/admin/tickets', params: { assignee_id: 'unassigned' }

      expect(json['tickets'].pluck('title')).to eq(['Unassigned'])
    end

    it 'searches by title or description' do
      Ticket.create!(title: 'VPN broken', description: 'nothing relevant', customer: customer)
      Ticket.create!(title: 'Printer', description: 'VPN mentioned here too', customer: customer)
      Ticket.create!(title: 'Unrelated', description: 'nope', customer: customer)
      login_as(admin)

      get '/api/v1/admin/tickets', params: { q: 'vpn' }

      expect(json['tickets'].pluck('title')).to contain_exactly('VPN broken', 'Printer')
    end
  end
end
