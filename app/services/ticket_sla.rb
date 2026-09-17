# frozen_string_literal: true

class TicketSla
  REMINDER_WAIT_BY_PRIORITY = {
    urgent: 4.hours,
    high: 8.hours,
    medium: 24.hours,
    low: 72.hours
  }.freeze

  # A ticket enters :at_risk once less than this fraction of its SLA window remains.
  AT_RISK_THRESHOLD = 0.25

  class << self
    def reminder_wait(priority)
      REMINDER_WAIT_BY_PRIORITY.fetch(priority.to_sym, 24.hours)
    end

    def due_at(ticket)
      ticket.created_at + reminder_wait(ticket.priority)
    end

    def state(ticket)
      remaining = due_at(ticket) - Time.current
      return :breached if remaining <= 0
      return :at_risk if remaining <= reminder_wait(ticket.priority) * AT_RISK_THRESHOLD

      :ok
    end
  end
end
