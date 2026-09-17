# frozen_string_literal: true

# Ruby 2.6 + OpenSSL 3 cannot commit AES-GCM session cookies (OpenSSL::Cipher::CipherError).
# load_defaults 5.2 enables GCM; Spring may also cache a stale @app_env_config. Force legacy
# CBC on every request env merge.
module Helpdesk
  module LegacyCookieEncryptionEnv
    def env_config
      super.tap do |config|
        config["action_dispatch.use_authenticated_cookie_encryption"] = false
      end
    end
  end
end

Rails.application.singleton_class.prepend(Helpdesk::LegacyCookieEncryptionEnv)

Rails.application.config.after_initialize do
  app = Rails.application
  app.instance_variable_set(:@app_env_config, nil) if app.instance_variable_defined?(:@app_env_config)
end
