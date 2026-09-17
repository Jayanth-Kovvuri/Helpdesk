# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Comments', type: :request do
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

  describe 'GET /api/v1/tickets/:ticket_id/comments' do
    before do
      Comment.create!(body: 'First reply', ticket: ticket, user: admin)
    end

    it 'lists comments when user can view the ticket' do
      login_as(customer)
      get "/api/v1/tickets/#{ticket.id}/comments"

      expect(response).to have_http_status(:ok)
      expect(json['comments'].size).to eq(1)
      expect(json['comments'].first['body']).to eq('First reply')
    end

    it 'forbids listing comments on another customers ticket' do
      other = User.create!(email: 'other@helpdesk.local', password: 'password123', role: :customer)
      other_ticket = Ticket.create!(title: 'Email', customer: other)
      login_as(customer)
      get "/api/v1/tickets/#{other_ticket.id}/comments"

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/tickets/:ticket_id/comments' do
    it 'creates a comment for an authorized user' do
      login_as(customer)
      post "/api/v1/tickets/#{ticket.id}/comments", params: {
        comment: { body: 'Still broken' }
      }

      expect(response).to have_http_status(:created)
      expect(json['comment']['body']).to eq('Still broken')
      expect(json['comment']['author']['id']).to eq(customer.id)
    end

    it 'emails the assignee when the customer comments' do
      ticket.update!(assignee: admin)
      login_as(customer)

      perform_enqueued_jobs do
        post "/api/v1/tickets/#{ticket.id}/comments", params: {
          comment: { body: 'Any update?' }
        }
      end

      expect(response).to have_http_status(:created)
      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([[admin.email]])
    end

    it 'sanitizes HTML in the request body' do
      login_as(admin)
      post "/api/v1/tickets/#{ticket.id}/comments", params: {
        comment: { body: '<b>bold</b> ok' }
      }

      expect(response).to have_http_status(:created)
      expect(json['comment']['body']).to eq('bold ok')
    end
  end

  describe 'DELETE /api/v1/tickets/:ticket_id/comments/:id' do
    let!(:comment) { Comment.create!(body: 'Remove me', ticket: ticket, user: customer) }

    it 'allows the author to delete' do
      login_as(customer)
      delete "/api/v1/tickets/#{ticket.id}/comments/#{comment.id}"

      expect(response).to have_http_status(:no_content)
      expect(Comment.find_by(id: comment.id)).to be_nil
    end

    it 'forbids another customer from deleting' do
      other = User.create!(email: 'other2@helpdesk.local', password: 'password123', role: :customer)
      login_as(other)
      delete "/api/v1/tickets/#{ticket.id}/comments/#{comment.id}"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
