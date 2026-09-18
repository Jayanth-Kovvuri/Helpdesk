# frozen_string_literal: true

class TicketSla
  # SLA thresholds in days for each priority
  SLA_THRESHOLDS_BY_PRIORITY = {
    urgent: { sla_days: 2, at_risk_days: 1 },
    high: { sla_days: 3, at_risk_days: 2 },
    medium: { sla_days: 5, at_risk_days: 3 },
    low: { sla_days: 7, at_risk_days: 5 }
  }.freeze

  class << self
    def sla_config(priority)
      SLA_THRESHOLDS_BY_PRIORITY.fetch(priority.to_sym, SLA_THRESHOLDS_BY_PRIORITY[:medium])
    end

    def sla_days(priority)
      sla_config(priority)[:sla_days]
    end

    def at_risk_days(priority)
      sla_config(priority)[:at_risk_days]
    end

    def due_at(ticket)
      ticket.created_at + sla_days(ticket.priority).days
    end

    def days_elapsed(ticket)
      ((Time.current - ticket.created_at) / 1.day).round(2)
    end

    def state(ticket)
      elapsed = days_elapsed(ticket)
      sla_threshold = sla_days(ticket.priority)
      at_risk_threshold = at_risk_days(ticket.priority)

      return :breached if elapsed > sla_threshold
      return :at_risk if elapsed > at_risk_threshold

      :ok
    end
  end
end
