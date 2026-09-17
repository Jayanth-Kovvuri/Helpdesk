# frozen_string_literal: true

class AttachmentBlueprint < Blueprinter::Base
  identifier :id

  field :filename do |attachment|
    attachment.filename.to_s
  end

  fields :content_type, :byte_size

  field :url do |attachment, options|
    host = options[:host] || 'localhost:3000'
    protocol = options[:protocol] || 'http'
    Rails.application.routes.url_helpers.rails_blob_url(
      attachment,
      host: host,
      protocol: protocol
    )
  end

  field :uploaded_by do |attachment|
    user_id = attachment.metadata['user_id']
    if user_id
      user = User.find_by(id: user_id)
      UserBlueprint.render_as_hash(user) if user
    end
  end
end
