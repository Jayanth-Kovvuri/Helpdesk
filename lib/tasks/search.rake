# frozen_string_literal: true

namespace :search do
  desc 'Reindex all tickets in Elasticsearch (requires ELASTICSEARCH_URL)'
  task reindex_tickets: :environment do
    abort 'Set ELASTICSEARCH_URL before reindexing.' unless TicketSearch.configured?

    puts 'Reindexing tickets...'
    Ticket.reindex
    puts 'Done.'
  end
end
