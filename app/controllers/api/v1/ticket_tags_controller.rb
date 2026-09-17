# frozen_string_literal: true

module Api
  module V1
    class TicketTagsController < BaseController
      include Api::TicketTagActions
    end
  end
end
