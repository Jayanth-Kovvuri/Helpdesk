# frozen_string_literal: true

module Api
  module V1
    class TicketSlaNotificationsController < BaseController
      before_action :require_admin!
      before_action :set_ticket

      # POST /api/v1/tickets/:ticket_id/sla_notify
      def create
        unless TicketSla.tracked?(@ticket)
          return render json: { error: I18n.t('api.errors.sla_not_applicable') }, status: :unprocessable_entity
        end

        recipient = ENV['NOTIFICATION_EMAIL'].presence
        if recipient.blank?
          return render json: { error: I18n.t('api.errors.notification_email_missing') }, status: :unprocessable_entity
        end

        TicketNotifications.notify_sla(@ticket, deliver_now: true)

        render json: { ok: true, sent_to: recipient }
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def set_ticket
        @ticket = Ticket.find(params[:ticket_id])
      end
    end
  end
end
