# frozen_string_literal: true

class TicketSlaAnalytics
  CACHE_TTL = 2.minutes
  CACHE_KEY_PREFIX = 'sla_analytics/v1'
  DEFAULT_PERIOD_DAYS = 30
  MAX_PERIOD_DAYS = 183
  CLOSED_STATUSES = %i[resolved closed].freeze
  PRIORITIES = TicketSla::SLA_THRESHOLDS_BY_PRIORITY.keys.freeze

  class << self
    def report(from: nil, to: nil, priority: nil)
      range = resolve_range(from, to)
      cache_key = [CACHE_KEY_PREFIX, range[:from].to_i, range[:to].to_i, priority.presence]

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        new(**range, priority: priority).build
      end
    end

    def bust_cache!
      return unless Rails.cache.respond_to?(:delete_matched)

      Rails.cache.delete_matched("#{CACHE_KEY_PREFIX}*")
    end

    private

    def resolve_range(from, to)
      ending = parse_time(to) || Time.current
      ending = [ending, Time.current].min
      starting = parse_time(from) || (ending - DEFAULT_PERIOD_DAYS.days)
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

  def initialize(from:, to:, priority: nil)
    @from = from
    @to = to
    @priority = priority.presence&.to_sym
  end

  def build
    closed = closed_tickets.to_a
    resolve_days = closed.map { |ticket| time_to_resolve_days(ticket) }
    compliant_count = closed.count { |ticket| sla_compliant?(ticket) }
    breach_count = closed.count { |ticket| breached_at_close?(ticket) }

    {
      period: { from: @from.iso8601, to: @to.iso8601 },
      summary: {
        closed_count: closed.size,
        sla_compliance_rate: rate(compliant_count, closed.size),
        median_time_to_resolve_days: percentile(resolve_days, 50),
        p90_time_to_resolve_days: percentile(resolve_days, 90),
        sla_breach_escalations_count: breach_count,
        sla_breach_escalations_rate: rate(breach_count, closed.size)
      },
      by_priority: priority_breakdown(closed),
      by_assignee: assignee_breakdown(closed)
    }
  end

  private

  def closed_tickets
    scope = Ticket.where(status: CLOSED_STATUSES, updated_at: @from..@to)
    scope = scope.where(priority: @priority) if @priority
    scope.includes(:assignee)
  end

  def active_tickets
    scope = Ticket.where(status: TicketSla::ACTIVE_STATUSES)
    scope = scope.where(priority: @priority) if @priority
    scope.includes(:assignee)
  end

  def time_to_resolve_days(ticket)
    ((ticket.updated_at - ticket.created_at) / 1.day).round(2)
  end

  def sla_compliant?(ticket)
    time_to_resolve_days(ticket) <= TicketSla.sla_days(ticket.priority)
  end

  def breached_at_close?(ticket)
    !sla_compliant?(ticket)
  end

  def rate(numerator, denominator)
    return 0.0 if denominator.zero?

    (numerator.to_f / denominator).round(4)
  end

  def percentile(values, percent)
    return nil if values.empty?

    sorted = values.sort
    index = ((percent / 100.0) * (sorted.length - 1)).round
    sorted[index]
  end

  def priority_breakdown(closed)
    PRIORITIES.map do |priority|
      subset = closed.select { |ticket| ticket.priority.to_sym == priority }
      days = subset.map { |ticket| time_to_resolve_days(ticket) }
      compliant = subset.count { |ticket| sla_compliant?(ticket) }
      breached = subset.count { |ticket| breached_at_close?(ticket) }

      {
        code: priority.to_s,
        label: I18n.t("ticket.priorities.#{priority}", default: priority.to_s.humanize),
        closed_count: subset.size,
        sla_compliance_rate: rate(compliant, subset.size),
        median_time_to_resolve_days: percentile(days, 50),
        sla_breach_escalations_count: breached
      }
    end
  end

  def assignee_breakdown(closed)
    rows = Hash.new do |hash, key|
      hash[key] = {
        assignee_id: key,
        email: nil,
        active_breached: 0,
        active_at_risk: 0,
        active_ok: 0,
        closed_in_period: 0
      }
    end

    active_tickets.find_each do |ticket|
      key = ticket.assignee_id
      row = rows[key]
      row[:email] = assignee_email(ticket)
      state = TicketSla.state(ticket)
      case state
      when :breached then row[:active_breached] += 1
      when :at_risk then row[:active_at_risk] += 1
      when :ok then row[:active_ok] += 1
      end
    end

    closed.each do |ticket|
      key = ticket.assignee_id
      row = rows[key]
      row[:email] = assignee_email(ticket)
      row[:closed_in_period] += 1
    end

    rows.values.sort_by { |row| [-row[:active_breached], row[:email].to_s] }
  end

  def assignee_email(ticket)
    ticket.assignee&.email
  end
end
