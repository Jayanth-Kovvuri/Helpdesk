# frozen_string_literal: true

namespace :storage do
  desc 'Create the MinIO bucket if it does not exist (requires MINIO_* env vars)'
  task ensure_minio_bucket: :environment do
    unless HelpdeskStorage.minio_configured?
      abort 'Set MINIO_ACCESS_KEY_ID and MINIO_SECRET_ACCESS_KEY (see .env.example).'
    end

    require 'aws-sdk-s3'

    bucket = ENV.fetch('MINIO_BUCKET', 'helpdesk')
    client = Aws::S3::Client.new(
      access_key_id: ENV['MINIO_ACCESS_KEY_ID'],
      secret_access_key: ENV['MINIO_SECRET_ACCESS_KEY'],
      region: ENV.fetch('MINIO_REGION', 'us-east-1'),
      endpoint: ENV.fetch('MINIO_ENDPOINT', 'http://127.0.0.1:9000'),
      force_path_style: true
    )

    if client.list_buckets.buckets.any? { |b| b.name == bucket }
      puts "MinIO bucket already exists: #{bucket}"
    else
      client.create_bucket(bucket: bucket)
      puts "Created MinIO bucket: #{bucket}"
    end
  rescue Aws::S3::Errors::ServiceError => e
    abort "MinIO error: #{e.message}"
  end
end
