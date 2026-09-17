# frozen_string_literal: true

module HelpdeskStorage
  module_function

  def service_name
    return :minio if minio_configured?
    return :amazon if aws_s3_configured?

    :local
  end

  def minio_configured?
    ENV['MINIO_ACCESS_KEY_ID'].present? && ENV['MINIO_SECRET_ACCESS_KEY'].present?
  end

  def aws_s3_configured?
    ENV['AWS_ACCESS_KEY_ID'].present? &&
      ENV['AWS_SECRET_ACCESS_KEY'].present? &&
      ENV['AWS_BUCKET'].present?
  end
end
