# frozen_string_literal: true

class TicketSlaReminderJob < ApplicationJob
  queue_as :default

  def perform(ticket_id)
    ticket = Ticket.find_by(id: ticket_id)
    return unless ticket
    return if ticket.resolved? || ticket.closed?

    if TicketSla.state(ticket) == :breached
      TicketNotifications.sla_breach(ticket)
    else
      TicketNotifications.sla_reminder(ticket)
    end
  end
end
