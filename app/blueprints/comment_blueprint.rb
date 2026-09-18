# frozen_string_literal: true

class CommentBlueprint < Blueprinter::Base
  identifier :id

  fields :body, :created_at, :updated_at

  field :author do |comment|
    UserBlueprint.render_as_hash(comment.user)
  end

  field :attachments do |comment, options|
    grouped = options[:attachments_by_comment_id] || {}
    records = grouped[comment.id] || []
    AttachmentBlueprint.render_as_hash(records, options)
  end
end
