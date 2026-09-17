# frozen_string_literal: true

class CommentBlueprint < Blueprinter::Base
  identifier :id

  fields :body, :created_at, :updated_at

  field :author do |comment|
    UserBlueprint.render_as_hash(comment.user)
  end
end
