# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Tags', type: :request do
  let!(:customer) do
    User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer)
  end

  describe 'GET /api/v1/tags' do
    it 'lists all tags for autocomplete' do
      Tag.create!(name: 'network')
      Tag.create!(name: 'billing')
      login_as(customer)

      get '/api/v1/tags'

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['tags'].pluck('name')).to eq(%w[billing network])
    end

    it 'requires login' do
      get '/api/v1/tags'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
