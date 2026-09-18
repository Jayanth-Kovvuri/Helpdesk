# frozen_string_literal: true

class TicketSlaScheduler
  def self.schedule_reminder(ticket)
    sla_days = TicketSla.sla_days(ticket.priority)
    wait = sla_days.days
    TicketSlaReminderJob.set(wait: wait).perform_later(ticket.id)
  end
end
