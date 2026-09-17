# frozen_string_literal: true

module AttachmentValidations
  extend ActiveSupport::Concern

  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    application/pdf
    text/plain
  ].freeze

  MAX_FILE_SIZE = 5.megabytes

  class_methods do
    def allowed_upload?(uploaded_file)
      return false if uploaded_file.blank?

      ALLOWED_CONTENT_TYPES.include?(uploaded_file.content_type) &&
        uploaded_file.size <= MAX_FILE_SIZE
    end
  end
end
