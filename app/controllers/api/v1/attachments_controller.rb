# frozen_string_literal: true

module Api
  module V1
    class AttachmentsController < BaseController
      include Api::AttachmentActions
    end
  end
end
