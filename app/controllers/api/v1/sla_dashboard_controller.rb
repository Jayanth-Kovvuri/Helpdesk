# frozen_string_literal: true

module Api
  module V1
    class SlaDashboardController < BaseController
      before_action :require_admin!

      def show
        render json: TicketSlaDashboard.summary(from: params[:from], to: params[:to])
      end
    end
  end
end
