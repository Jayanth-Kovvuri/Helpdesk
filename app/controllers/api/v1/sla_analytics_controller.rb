# frozen_string_literal: true

module Api
  module V1
    class SlaAnalyticsController < BaseController
      before_action :require_admin!

      # GET /api/v1/sla_analytics?from=&to=&priority=
      def show
        render json: TicketSlaAnalytics.report(
          from: params[:from],
          to: params[:to],
          priority: params[:priority]
        )
      end
    end
  end
end
