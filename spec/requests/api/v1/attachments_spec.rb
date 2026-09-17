# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Attachments', type: :request do
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:ticket) { Ticket.create!(title: 'VPN', customer: customer) }

  def json
    JSON.parse(response.body)
  end

  def sample_file
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec/fixtures/files/sample.txt'),
      'text/plain'
    )
  end

  describe 'GET /api/v1/tickets/:ticket_id/attachments' do
    it 'lists attachments for an authorized user' do
      login_as(customer)
      post "/api/v1/tickets/#{ticket.id}/attachments", params: { attachment: { file: sample_file } }

      get "/api/v1/tickets/#{ticket.id}/attachments"

      expect(response).to have_http_status(:ok)
      expect(json['attachments']).to contain_exactly(
        hash_including(
          'filename' => 'sample.txt',
          'url' => a_string_including('/rails/active_storage/blobs/')
        )
      )
    end
  end

  describe 'POST /api/v1/tickets/:ticket_id/attachments' do
    it 'uploads a file and records the uploader' do
      login_as(customer)
      post "/api/v1/tickets/#{ticket.id}/attachments", params: { attachment: { file: sample_file } }

      expect(response).to have_http_status(:created)
      expect(json['attachment']['uploaded_by']['id']).to eq(customer.id)
    end

    it 'rejects disallowed content types' do
      login_as(admin)
      bad_file = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/sample.txt'),
        'application/x-msdownload'
      )
      post "/api/v1/tickets/#{ticket.id}/attachments", params: { attachment: { file: bad_file } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/tickets/:ticket_id/attachments/:id' do
    it 'allows the uploader to delete their attachment' do
      login_as(customer)
      post "/api/v1/tickets/#{ticket.id}/attachments", params: { attachment: { file: sample_file } }
      attachment_id = json['attachment']['id']

      delete "/api/v1/tickets/#{ticket.id}/attachments/#{attachment_id}"

      expect(response).to have_http_status(:no_content)
      expect(ticket.reload.attachments.count).to eq(0)
    end
  end
end
