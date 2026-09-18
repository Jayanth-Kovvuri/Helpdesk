# frozen_string_literal: true

class UserSearch
  MIN_QUERY_LENGTH = 2

  class << self
    def call(query:, role: nil, exclude_disabled: false)
      new(query: query, role: role, exclude_disabled: exclude_disabled).call
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
  end

  def initialize(query:, role: nil, exclude_disabled: false)
    @query = query.to_s.strip
    @role = role.presence
    @exclude_disabled = exclude_disabled
  end

  def call
    return scoped_users if @query.length < MIN_QUERY_LENGTH

    if self.class.use_elasticsearch?
      search_with_elasticsearch
    else
      search_with_sql
    end
  end

  private

  def search_with_elasticsearch
    User.search(
      @query,
      where: elasticsearch_filters,
      fields: [{ name: :word_middle }, { email: :word_middle }],
      load: true,
      order: { created_at: :desc },
      misspellings: { below: 2 }
    )
  rescue Searchkick::MissingIndexError => e
    Rails.logger.warn("User search index missing (#{e.message}). Run: bundle exec rake search:reindex")
    search_with_sql
  rescue StandardError => e
    Rails.logger.warn("User Elasticsearch search failed: #{e.message}")
    search_with_sql
  end

  def search_with_sql
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    scoped_users
      .where('name ILIKE :q OR email ILIKE :q', q: pattern)
      .order(created_at: :desc)
  end

  def scoped_users
    scope = User.all
    scope = scope.where(role: @role) if @role.present?
    scope = scope.where(disabled_at: nil) if @exclude_disabled
    scope.order(created_at: :desc)
  end

  def elasticsearch_filters
    filters = {}
    filters[:role] = @role if @role.present?
    filters[:disabled] = false if @exclude_disabled
    filters
  end
end
