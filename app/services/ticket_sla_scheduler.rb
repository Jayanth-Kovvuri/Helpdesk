# frozen_string_literal: true

class TicketSlaScheduler
  def self.schedule_reminder(ticket)
    wait = TicketSla.reminder_wait(ticket.priority)
    TicketSlaReminderJob.set(wait: wait).perform_later(ticket.id)
  end
end
