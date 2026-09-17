# frozen_string_literal: true

module Api
  module V1
    class SlaDashboardController < BaseController
      before_action :require_admin!

      def show
        render json: TicketSlaDashboard.summary
      end
    end
  end
end
