# frozen_string_literal: true

module AuthHelpers
  def login_as(user, password: 'password123')
    post '/api/v1/session', params: { email: user.email, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
