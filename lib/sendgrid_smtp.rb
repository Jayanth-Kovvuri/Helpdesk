# frozen_string_literal: true

module SendgridSmtp
  module_function

  def enabled?
    ENV['SENDGRID_API_KEY'].present?
  end

  def settings
    {
      address: ENV.fetch('SENDGRID_SMTP_ADDRESS', 'smtp.sendgrid.net'),
      port: ENV.fetch('SENDGRID_SMTP_PORT', '587').to_i,
      domain: ENV.fetch('SMTP_DOMAIN', 'localhost'),
      user_name: 'apikey',
      password: ENV['SENDGRID_API_KEY'],
      authentication: :plain,
      enable_starttls_auto: true
    }
  end

  def apply!(config)
    return unless enabled?

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = settings
    config.action_mailer.raise_delivery_errors = true
  end
end
