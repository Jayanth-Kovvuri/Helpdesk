# frozen_string_literal: true

class TicketSlaDashboard
  CACHE_TTL = 30.seconds
  CACHE_KEY_PREFIX = 'sla_dashboard/v3'
  MAX_PERIOD_DAYS = TicketSlaAnalytics::MAX_PERIOD_DAYS

  class << self
    def summary(from: nil, to: nil)
      range =
        if from.present? && to.present?
          resolve_range(from, to)
        else
          { from: nil, to: nil }
        end
      cache_key = [CACHE_KEY_PREFIX, range[:from]&.to_i, range[:to]&.to_i]

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { new(**range).build }
    end

    def bust_cache!
      return unless Rails.cache.respond_to?(:delete_matched)

      Rails.cache.delete_matched("#{CACHE_KEY_PREFIX}*")
    end

    private

    def resolve_range(from, to)
      return { from: nil, to: nil } if from.blank? && to.blank?

      ending = parse_time(to) || Time.current
      ending = [ending, Time.current].min
      starting = parse_time(from) || (ending - TicketSlaAnalytics::DEFAULT_PERIOD_DAYS.days)
      earliest_allowed = ending - MAX_PERIOD_DAYS.days
      starting = [starting, earliest_allowed].max
      starting = [starting, ending].min
      { from: starting.beginning_of_day, to: ending.end_of_day }
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end

  def initialize(from: nil, to: nil)
    @from = from
    @to = to
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
    scope = Ticket.where(status: TicketSla::ACTIVE_STATUSES)
    return scope if @from.blank? || @to.blank?

    scope.where(created_at: @from..@to)
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
