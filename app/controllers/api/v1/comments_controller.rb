# frozen_string_literal: true

module Api
  module V1
    class CommentsController < BaseController
      include Api::CommentActions

      private

      def comment_blueprint
        CommentBlueprint
      end
    end
  end
end
