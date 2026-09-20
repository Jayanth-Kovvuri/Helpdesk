# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Helpdesk
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # load_defaults 5.2 turns on AES-GCM cookie encryption, which raises
    # OpenSSL::Cipher::CipherError on Ruby 2.6 + OpenSSL 3 when committing sessions.
    config.action_dispatch.use_authenticated_cookie_encryption = false
    config.active_support.use_authenticated_message_encryption = false

    config.autoload_paths += %W[
      #{config.root}/app/blueprints
      #{config.root}/app/services
    ]

    config.i18n.available_locales = %i[en es ar]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
