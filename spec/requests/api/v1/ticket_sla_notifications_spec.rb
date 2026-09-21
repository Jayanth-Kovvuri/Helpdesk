# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TicketSlaNotifications', type: :request do
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:ticket) { Ticket.create!(title: 'SLA notify', description: 'Test', customer: customer, priority: :high) }

  describe 'POST /api/v1/tickets/:ticket_id/sla_notify' do
    it 'sends SLA mail to NOTIFICATION_EMAIL for admins' do
      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      login_as(admin)

      expect do
        post "/api/v1/tickets/#{ticket.id}/sla_notify"
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('ok' => true, 'sent_to' => 'notify@example.com')
      expect(ActionMailer::Base.deliveries.last.to).to eq(['notify@example.com'])
    ensure
      ENV.delete('NOTIFICATION_EMAIL')
    end

    it 'forbids customers' do
      login_as(customer)
      post "/api/v1/tickets/#{ticket.id}/sla_notify"

      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects resolved or closed tickets' do
      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      ticket.update!(status: :closed)
      login_as(admin)

      post "/api/v1/tickets/#{ticket.id}/sla_notify"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('SLA')
    ensure
      ENV.delete('NOTIFICATION_EMAIL')
    end
  end
end
