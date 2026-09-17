# frozen_string_literal: true

# Allow the future React dev server to call the API with session cookies.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5173', '127.0.0.1:5173', 'localhost:3000', '127.0.0.1:3000'

    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end
