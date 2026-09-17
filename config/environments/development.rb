# frozen_string_literal: true

require_relative '../helpdesk_cache'
require_relative '../helpdesk_storage'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Ruby 2.6 + OpenSSL 3.x cannot encrypt session cookies with AES-GCM (see test.rb).
  config.action_dispatch.use_authenticated_cookie_encryption = false

  # Phase 9: Redis cache when REDIS_URL / REDIS_CACHE_URL is set; else rails dev:cache → memory_store.
  HelpdeskCache.configure_rails!(config)

  # MinIO (S3-compatible) when MINIO_* is set; else disk under storage/ (see config/storage.yml).
  config.active_storage.service = HelpdeskStorage.service_name

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  config.action_mailer.perform_caching = false

  # Phase 7: Sidekiq when Redis is available; otherwise in-process :async (no worker needed).
  config.active_job.queue_adapter = ENV['REDIS_URL'].present? ? :sidekiq : :async

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
