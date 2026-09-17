# frozen_string_literal: true

class TicketSlaReminderJob < ApplicationJob
  queue_as :default

  def perform(ticket_id)
    ticket = Ticket.find_by(id: ticket_id)
    return unless ticket
    return if ticket.resolved? || ticket.closed?

    TicketNotifications.sla_reminder(ticket)
  end
end
