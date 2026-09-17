# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('config/helpdesk_storage')

RSpec.describe HelpdeskStorage do
  around do |example|
    env = %w[MINIO_ACCESS_KEY_ID MINIO_SECRET_ACCESS_KEY AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_BUCKET]
    saved = env.to_h { |key| [key, ENV[key]] }
    env.each { |key| ENV.delete(key) }
    example.run
  ensure
    saved.each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
  end

  it 'prefers MinIO when MINIO credentials are set' do
    ENV['MINIO_ACCESS_KEY_ID'] = 'minioadmin'
    ENV['MINIO_SECRET_ACCESS_KEY'] = 'minioadmin'

    expect(described_class.service_name).to eq(:minio)
  end

  it 'uses AWS when only AWS credentials are set' do
    ENV['AWS_ACCESS_KEY_ID'] = 'key'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'secret'
    ENV['AWS_BUCKET'] = 'prod-bucket'

    expect(described_class.service_name).to eq(:amazon)
  end

  it 'falls back to local disk when no object storage is configured' do
    expect(described_class.service_name).to eq(:local)
  end
end
