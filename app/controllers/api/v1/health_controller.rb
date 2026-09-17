# frozen_string_literal: true

module Api
  module V1
    class HealthController < ApplicationController
      def show
        checks = HealthCheck.run
        healthy = checks.values.all?
        status = healthy ? :ok : :service_unavailable

        render json: {
          status: healthy ? 'ok' : 'degraded',
          checks: checks
        }, status: status
      end
    end
  end
end
