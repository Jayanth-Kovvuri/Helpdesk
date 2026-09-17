# frozen_string_literal: true

module Api
  module V1
    class TicketsController < BaseController
      include Api::TicketActions

      private

      def ticket_blueprint
        TicketBlueprint
      end
    end
  end
end
