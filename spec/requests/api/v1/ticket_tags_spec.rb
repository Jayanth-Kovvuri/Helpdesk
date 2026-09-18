# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TicketTags', type: :request do
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end
  let!(:admin) do
    User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin)
  end
  let!(:ticket) { Ticket.create!(title: 'VPN', customer: customer) }

  def json
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/tickets/:ticket_id/tags' do
    it 'lists tags attached to the ticket' do
      ticket.tags << Tag.create!(name: 'network')
      login_as(customer)

      get "/api/v1/tickets/#{ticket.id}/tags"

      expect(response).to have_http_status(:ok)
      expect(json['tags'].pluck('name')).to eq(['network'])
    end

    it 'forbids viewing tags on another customers ticket' do
      other = User.create!(email: 'other@helpdesk.local', name: 'other@helpdesk.local', password: 'password123', role: :customer)
      other_ticket = Ticket.create!(title: 'Email', customer: other)
      login_as(customer)

      get "/api/v1/tickets/#{other_ticket.id}/tags"

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/tickets/:ticket_id/tags' do
    it 'attaches an existing or new tag by name' do
      login_as(customer)

      post "/api/v1/tickets/#{ticket.id}/tags", params: { tag: { name: 'Network' } }

      expect(response).to have_http_status(:created)
      expect(json['tags'].pluck('name')).to eq(['network'])
      expect(ticket.reload.tags.pluck(:name)).to eq(['network'])
    end

    it 'reuses an existing tag instead of creating a duplicate' do
      Tag.create!(name: 'network')
      login_as(customer)

      expect do
        post "/api/v1/tickets/#{ticket.id}/tags", params: { tag: { name: 'network' } }
      end.not_to change(Tag, :count)

      expect(response).to have_http_status(:created)
    end

    it 'is idempotent when the tag is already attached' do
      tag = Tag.create!(name: 'network')
      ticket.tags << tag
      login_as(customer)

      post "/api/v1/tickets/#{ticket.id}/tags", params: { tag: { name: 'network' } }

      expect(response).to have_http_status(:created)
      expect(ticket.reload.tags.count).to eq(1)
    end

    it 'forbids a customer from tagging a closed ticket' do
      ticket.update!(status: :closed)
      login_as(customer)

      post "/api/v1/tickets/#{ticket.id}/tags", params: { tag: { name: 'network' } }

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows an admin to tag any ticket' do
      login_as(admin)

      post "/api/v1/tickets/#{ticket.id}/tags", params: { tag: { name: 'urgent-fix' } }

      expect(response).to have_http_status(:created)
    end
  end

  describe 'DELETE /api/v1/tickets/:ticket_id/tags/:id' do
    it 'detaches a tag from the ticket' do
      tag = Tag.create!(name: 'network')
      ticket.tags << tag
      login_as(customer)

      delete "/api/v1/tickets/#{ticket.id}/tags/#{tag.id}"

      expect(response).to have_http_status(:no_content)
      expect(ticket.reload.tags).to be_empty
    end
  end
end
