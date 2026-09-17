# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Tickets', type: :request do
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:other_customer) do
    User.create!(email: 'other@helpdesk.local', password: 'password123', role: :customer)
  end

  let!(:customer_ticket) do
    Ticket.create!(title: 'My printer', description: 'Jam', customer: customer, priority: :high)
  end
  let!(:other_ticket) do
    Ticket.create!(title: 'VPN down', customer: other_customer)
  end

  def json
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/tickets' do
    it 'lists all tickets for admin' do
      login_as(admin)
      get '/api/v1/tickets'

      expect(response).to have_http_status(:ok)
      ids = json['tickets'].map { |t| t['id'] }
      expect(ids).to contain_exactly(customer_ticket.id, other_ticket.id)
    end

    it 'lists only own tickets for customer' do
      login_as(customer)
      get '/api/v1/tickets'

      expect(response).to have_http_status(:ok)
      expect(json['tickets'].size).to eq(1)
      expect(json['tickets'].first['id']).to eq(customer_ticket.id)
    end

    it 'filters tickets when q is present on index' do
      login_as(admin)
      get '/api/v1/tickets', params: { q: 'printer' }

      expect(response).to have_http_status(:ok)
      ids = json['tickets'].map { |t| t['id'] }
      expect(ids).to eq([customer_ticket.id])
    end
  end

  describe 'GET /api/v1/tickets/:id' do
    it 'forbids customer from viewing another users ticket' do
      login_as(customer)
      get "/api/v1/tickets/#{other_ticket.id}"

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/tickets' do
    it 'lets customer create a ticket assigned to themselves' do
      login_as(customer)
      post '/api/v1/tickets', params: { ticket: { title: 'New issue', description: 'Details', priority: 'low' } }
      expect(response).to have_http_status(:created)
      ticket_json = json['ticket']
      expect(ticket_json.slice('title', 'status')).to eq(
        'title' => 'New issue',
        'status' => { 'code' => 'open', 'label' => 'Open' }
      )
      expect(ticket_json.dig('customer', 'id')).to eq(customer.id)
    end

    it 'emails admins when a customer creates a ticket' do
      login_as(customer)

      perform_enqueued_jobs(only: ActionMailer::DeliveryJob) do
        post '/api/v1/tickets', params: {
          ticket: { title: 'Mail test', description: 'Details', priority: 'low' }
        }
      end

      expect(response).to have_http_status(:created)
      expect(ActionMailer::Base.deliveries.flat_map(&:to)).to eq([admin.email])
    end

    it 'schedules an SLA reminder job when a ticket is created' do
      login_as(customer)

      expect do
        post '/api/v1/tickets', params: {
          ticket: { title: 'SLA job', description: 'Details', priority: 'urgent' }
        }
      end.to have_enqueued_job(TicketSlaReminderJob).on_queue('default')

      expect(response).to have_http_status(:created)
    end

    it 'lets admin assign customer and assignee' do
      login_as(admin)
      ticket_params = {
        title: 'Assigned work', customer_id: customer.id, assignee_id: admin.id,
        status: 'in_progress', priority: 'urgent'
      }
      post '/api/v1/tickets', params: { ticket: ticket_params }

      expect(response).to have_http_status(:created)
      expect(json['ticket']['status']['code']).to eq('in_progress')
      expect(json['ticket']['assignee']['id']).to eq(admin.id)
    end

    it 'emails the customer when an admin creates a ticket for them' do
      login_as(admin)

      perform_enqueued_jobs(only: ActionMailer::DeliveryJob) do
        post '/api/v1/tickets', params: {
          ticket: { title: 'Opened for you', description: 'Details', customer_id: customer.id }
        }
      end

      expect(response).to have_http_status(:created)
      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([[customer.email]])
    end
  end

  describe 'PATCH /api/v1/tickets/:id' do
    it 'lets admin update status and assignee' do
      login_as(admin)
      patch "/api/v1/tickets/#{customer_ticket.id}", params: {
        ticket: { status: 'in_progress', assignee_id: admin.id }
      }

      expect(response).to have_http_status(:ok)
      expect(json['ticket']['status']['code']).to eq('in_progress')
      expect(json['ticket']['assignee']['id']).to eq(admin.id)
    end

    it 'forbids customer from changing status' do
      login_as(customer)
      patch "/api/v1/tickets/#{customer_ticket.id}", params: {
        ticket: { title: 'Updated title', status: 'closed' }
      }

      expect(response).to have_http_status(:ok)
      customer_ticket.reload
      expect(customer_ticket.title).to eq('Updated title')
      expect(customer_ticket.status).to eq('open')
    end
  end

  describe 'DELETE /api/v1/tickets/:id' do
    it 'allows admin to delete' do
      login_as(admin)
      delete "/api/v1/tickets/#{customer_ticket.id}"

      expect(response).to have_http_status(:no_content)
      expect(Ticket.find_by(id: customer_ticket.id)).to be_nil
    end

    it 'forbids customer from deleting' do
      login_as(customer)
      delete "/api/v1/tickets/#{customer_ticket.id}"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
