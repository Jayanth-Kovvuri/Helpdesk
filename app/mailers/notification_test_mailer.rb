# frozen_string_literal: true

class NotificationTestMailer < ApplicationMailer
  def ping(recipient)
    mail(
      to: recipient,
      subject: '[Helpdesk] SendGrid test',
      body: test_body,
      content_type: 'text/plain'
    )
  end

  private

  def test_body
    <<~TEXT.strip
      Helpdesk notification test

      Sent at: #{Time.current.utc.iso8601}
      Environment: #{Rails.env}
      Delivery: #{ActionMailer::Base.delivery_method}
      SendGrid configured: #{SendgridSmtp.enabled?}
    TEXT
  end
end
