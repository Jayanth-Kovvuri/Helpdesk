# frozen_string_literal: true

class TicketSearch
  MIN_QUERY_LENGTH = 2

  class << self
    def call(user:, query:, filter: nil, status: nil, priority: nil)
      new(user: user, query: query, filter: filter, status: status, priority: priority).call
    end

    def configured?
      ENV['ELASTICSEARCH_URL'].present?
    end

    def use_elasticsearch?
      return false if Rails.env.test?
      return false unless configured?

      elasticsearch_alive?
    end

    def elasticsearch_alive?
      Searchkick.client.ping
    rescue StandardError
      false
    end

    def reindex_ticket!(ticket)
      return unless use_elasticsearch?

      ticket.reindex
    end
  end

  def initialize(user:, query:, filter: nil, status: nil, priority: nil)
    @user = user
    @query = query.to_s.strip
    @filter = filter
    @status = status
    @priority = priority
  end

  def call
    return Ticket.none if @query.length < MIN_QUERY_LENGTH

    if self.class.use_elasticsearch?
      search_with_elasticsearch
    else
      search_with_sql
    end
  end

  private

  def search_with_elasticsearch
    result_ids = Ticket.search(
      @query,
      where: elasticsearch_filters,
      fields: [
        { title: :word_middle },
        { description: :word_middle },
        { tag_names: :word_middle }
      ],
      load: false,
      order: { created_at: :desc },
      misspellings: { below: 2 }
    ).map(&:id)

    return tickets_for_ids(result_ids) if result_ids.any?

    search_with_sql
  rescue StandardError => e
    Rails.logger.warn("Ticket Elasticsearch search failed: #{e.message}")
    search_with_sql
  end

  def tickets_for_ids(result_ids)
    records = Ticket.where(id: result_ids)
                    .includes(:customer, :assignee, :comments, :tags, { attachments_attachments: :blob })
                    .index_by(&:id)
    result_ids.map { |id| records[id.to_i] }.compact
  end

  def search_with_sql
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    scope = Ticket.visible_to(@user)
                  .where(
                    'title ILIKE :q OR description ILIKE :q',
                    q: pattern
                  )

    case @filter
    when 'raised'
      scope = scope.where(customer_id: @user.id)
    when 'assigned'
      scope = scope.where(assignee_id: @user.id)
    end

    scope = scope.where(status: @status) if @status.present?
    scope = scope.where(priority: @priority) if @priority.present?

    scope.includes(:customer, :assignee, :comments, :tags, { attachments_attachments: :blob })
         .order(created_at: :desc)
  end

  def elasticsearch_filters
    filters = {}

    case @filter
    when 'raised'
      filters[:customer_id] = @user.id
    when 'assigned'
      filters[:assignee_id] = @user.id
    else
      filters[:customer_id] = @user.id unless @user.admin?
    end

    filters[:status] = @status if @status.present?
    filters[:priority] = @priority if @priority.present?

    filters
  end
end
