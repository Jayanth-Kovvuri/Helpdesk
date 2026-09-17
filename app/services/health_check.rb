# frozen_string_literal: true

class HealthCheck
  class << self
    def run
      new.status
    end

    def ok?
      run.values.all?
    end
  end

  def status
    {
      database: database_ok?,
      redis: redis_ok?,
      elasticsearch: elasticsearch_ok?
    }
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def redis_ok?
    return true unless HelpdeskCache.use_redis?

    Redis.new(url: HelpdeskCache.redis_url).ping == 'PONG'
  rescue StandardError
    false
  end

  def elasticsearch_ok?
    return true unless TicketSearch.configured?

    TicketSearch.elasticsearch_alive?
  end
end
