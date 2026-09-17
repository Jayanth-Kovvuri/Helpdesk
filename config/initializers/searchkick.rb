# frozen_string_literal: true

if ENV['ELASTICSEARCH_URL'].present?
  Searchkick.client = Elasticsearch::Client.new(
    url: ENV['ELASTICSEARCH_URL'],
    transport_options: { request: { timeout: 5 } }
  )
end

Searchkick.disable_callbacks if Rails.env.test? || ENV['ELASTICSEARCH_URL'].blank?
