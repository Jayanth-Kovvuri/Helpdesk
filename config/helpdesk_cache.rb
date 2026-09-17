# frozen_string_literal: true

module HelpdeskCache
  module_function

  def redis_url
    ENV.fetch('REDIS_CACHE_URL', ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'))
  end

  def redis_options
    {
      url: redis_url,
      namespace: "helpdesk:cache:#{Rails.env}"
    }
  end

  def use_redis?
    ENV['REDIS_CACHE_URL'].present? || ENV['REDIS_URL'].present?
  end

  def configure_rails!(config)
    apply_store!(config)
    apply_public_file_headers!(config)
  end

  def apply_store!(config)
    config.cache_store = store_for_environment
    config.action_controller.perform_caching = caching_enabled?
  end

  def store_for_environment
    return :memory_store if Rails.env.test?
    return :redis_cache_store, redis_options if Rails.env.production?
    return :redis_cache_store, redis_options if use_redis?
    return :memory_store if dev_memory_cache_enabled?

    :null_store
  end

  def caching_enabled?
    return true if Rails.env.test? || Rails.env.production?
    return true if use_redis?
    return true if dev_memory_cache_enabled?

    false
  end

  def dev_memory_cache_enabled?
    Rails.env.development? && Rails.root.join('tmp/caching-dev.txt').exist?
  end

  def apply_public_file_headers!(config)
    return unless dev_memory_cache_enabled?

    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  end
end
