# frozen_string_literal: true

class TicketSlaDashboard
  CACHE_TTL = 30.seconds
  ACTIVE_STATUSES = %i[open in_progress pending].freeze

  class << self
    def summary
      Rails.cache.fetch('sla_dashboard/v2', expires_in: CACHE_TTL) { new.build }
    end
  end

  def build
    grouped = active_tickets.group_by { |ticket| TicketSla.state(ticket) }

    {
      counts: {
        breached: grouped.fetch(:breached, []).size,
        at_risk: grouped.fetch(:at_risk, []).size,
        ok: grouped.fetch(:ok, []).size
      },
      breached_tickets: ticket_summaries(grouped.fetch(:breached, [])),
      at_risk_tickets: ticket_summaries(grouped.fetch(:at_risk, [])),
      ok_tickets: ticket_summaries(grouped.fetch(:ok, []))
    }
  end

  private

  def active_tickets
    Ticket.where(status: ACTIVE_STATUSES)
  end

  def ticket_summaries(tickets)
    tickets.sort_by { |ticket| TicketSla.due_at(ticket) }.map do |ticket|
      {
        id: ticket.id,
        title: ticket.title,
        priority: priority_field(ticket),
        due_at: TicketSla.due_at(ticket)
      }
    end
  end

  def priority_field(ticket)
    {
      code: ticket.priority,
      label: I18n.t("ticket.priorities.#{ticket.priority}", default: ticket.priority.humanize)
    }
  end
end
