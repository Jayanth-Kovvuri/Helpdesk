# frozen_string_literal: true

module Api
  module V1
    class NotificationTestsController < BaseController
      before_action :require_admin!

      # POST /api/v1/notification_test — sends one plain-text message to NOTIFICATION_EMAIL.
      def create
        recipient = ENV['NOTIFICATION_EMAIL'].presence
        if recipient.blank?
          return render json: { error: I18n.t('api.errors.notification_email_missing') }, status: :unprocessable_entity
        end

        NotificationTestMailer.ping(recipient).deliver_now

        render json: {
          ok: true,
          sent_to: recipient,
          delivery_method: ActionMailer::Base.delivery_method.to_s,
          sendgrid_configured: SendgridSmtp.enabled?
        }
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
