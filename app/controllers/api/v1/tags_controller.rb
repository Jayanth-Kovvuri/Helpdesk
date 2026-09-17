# frozen_string_literal: true

module Api
  module V1
    class TagsController < BaseController
      def index
        render json: { tags: TagBlueprint.render_as_hash(Tag.order(:name)) }
      end
    end
  end
end
