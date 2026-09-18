# frozen_string_literal: true

namespace :search do
  desc 'Reindex tickets and users in Elasticsearch (requires ELASTICSEARCH_URL)'
  task reindex: :environment do
    abort 'Set ELASTICSEARCH_URL before reindexing.' unless TicketSearch.configured?

    puts 'Reindexing tickets...'
    Ticket.reindex
    puts 'Reindexing users...'
    User.reindex
    puts 'Done.'
  end

  task reindex_tickets: :environment do
    abort 'Set ELASTICSEARCH_URL before reindexing.' unless TicketSearch.configured?

    puts 'Reindexing tickets...'
    Ticket.reindex
    puts 'Done.'
  end

  task reindex_users: :environment do
    unless UserSearch.configured?
      abort 'Set ELASTICSEARCH_URL before reindexing (see .env.example).'
    end

    count = User.count
    $stdout.puts "Reindexing #{count} user(s) into Elasticsearch..."
    User.reindex
    $stdout.puts "User reindex finished (#{count} indexed)."
  end
end
