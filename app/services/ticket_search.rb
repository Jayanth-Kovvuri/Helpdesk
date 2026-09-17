# frozen_string_literal: true

class TicketSearch
  MIN_QUERY_LENGTH = 2

  class << self
    def call(user:, query:)
      new(user: user, query: query).call
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

  def initialize(user:, query:)
    @user = user
    @query = query.to_s.strip
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
    Ticket.search(
      @query,
      where: elasticsearch_filters,
      fields: [{ title: :word_middle }, { description: :word_middle }, { comment_text: :word_middle }],
      load: true,
      order: { created_at: :desc },
      misspellings: { below: 2 }
    )
  end

  def search_with_sql
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    Ticket.visible_to(@user)
          .where('title ILIKE :q OR description ILIKE :q', q: pattern)
          .includes(:customer, :assignee, :comments, :tags, { attachments_attachments: :blob })
          .order(created_at: :desc)
  end

  def elasticsearch_filters
    @user.admin? ? {} : { customer_id: @user.id }
  end
end
