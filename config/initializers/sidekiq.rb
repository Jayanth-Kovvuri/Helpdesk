# frozen_string_literal: true

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

if defined?(Sidekiq::Web) && ENV['SIDEKIQ_WEB_USERNAME'].present?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    secure = ActiveSupport::SecurityUtils.method(:secure_compare)
    secure.call(username, ENV['SIDEKIQ_WEB_USERNAME']) &&
      secure.call(password, ENV.fetch('SIDEKIQ_WEB_PASSWORD', ''))
  end
end
