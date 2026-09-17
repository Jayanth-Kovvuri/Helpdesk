# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Health', type: :request do
  describe 'GET /api/v1/health' do
    it 'does not require authentication' do
      get '/api/v1/health'

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['status']).to eq('ok')
      expect(body['checks']['database']).to be(true)
    end
  end
end
