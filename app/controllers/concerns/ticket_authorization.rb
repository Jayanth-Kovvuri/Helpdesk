# frozen_string_literal: true

module TicketAuthorization
  extend ActiveSupport::Concern

  private

  def authorize_ticket_view!
    return if @ticket.visible_to?(current_user)

    render json: { error: I18n.t('api.errors.forbidden') }, status: :forbidden
  end

  def authorize_ticket_edit!
    return if @ticket.editable_by?(current_user)

    render json: { error: I18n.t('api.errors.forbidden') }, status: :forbidden
  end
end
