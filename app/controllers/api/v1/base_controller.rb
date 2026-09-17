# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Authenticatable

      protect_from_forgery with: :null_session
      # JSON API + cross-origin session cookies (React on :5173). CSRF tokens are not
      # sent from the SPA; without this skip, :null_session discards session writes on login.
      skip_before_action :verify_authenticity_token

      before_action :require_login
    end
  end
end
