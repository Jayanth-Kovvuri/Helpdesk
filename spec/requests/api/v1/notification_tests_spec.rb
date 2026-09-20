# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::NotificationTests', type: :request do
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end

  describe 'POST /api/v1/notification_test' do
    it 'sends a test email to NOTIFICATION_EMAIL for admins' do
      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      login_as(admin)

      expect do
        post '/api/v1/notification_test'
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('ok' => true, 'sent_to' => 'notify@example.com')
      expect(ActionMailer::Base.deliveries.last.to).to eq(['notify@example.com'])
      expect(ActionMailer::Base.deliveries.last.subject).to eq('[Helpdesk] SendGrid test')
    ensure
      ENV.delete('NOTIFICATION_EMAIL')
    end

    it 'returns unprocessable when NOTIFICATION_EMAIL is missing' do
      ENV.delete('NOTIFICATION_EMAIL')
      login_as(admin)

      post '/api/v1/notification_test'

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('NOTIFICATION_EMAIL')
    end

    it 'forbids customers' do
      login_as(customer)
      post '/api/v1/notification_test'

      expect(response).to have_http_status(:forbidden)
    end
  end
end
