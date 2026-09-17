# frozen_string_literal: true

class TicketResponseCache
  INDEX_TTL = 5.minutes
  SHOW_TTL = 10.minutes
  SEARCH_TTL = 2.minutes

  class << self
    def fetch_index(user, &block)
      Rails.cache.fetch(index_key(user), expires_in: INDEX_TTL, &block)
    end

    def fetch_show(ticket, &block)
      Rails.cache.fetch(show_key(ticket), expires_in: SHOW_TTL, &block)
    end

    def fetch_search(user, query, &block)
      Rails.cache.fetch(search_key(user, query), expires_in: SEARCH_TTL, &block)
    end

    def index_key(user)
      scope = Ticket.visible_to(user)
      ['tickets/v1/index', user.id, user.role, scope_version(scope)]
    end

    def show_key(ticket)
      ['tickets/v1/show', ticket.cache_key_with_version]
    end

    def search_key(user, query)
      scope = Ticket.visible_to(user)
      normalized = query.to_s.strip.downcase
      ['tickets/v1/search', user.id, user.role, scope_version(scope), normalized]
    end

    private

    def scope_version(scope)
      max_updated = scope.maximum(:updated_at)
      stamp = max_updated ? max_updated.utc.to_f : 0
      "#{stamp}-#{scope.count}"
    end
  end
end
