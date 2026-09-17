# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :require_login, only: :create

      def create
        user = authenticated_user

        if user.nil?
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        elsif user.disabled?
          render json: { error: I18n.t('api.errors.account_disabled') }, status: :unauthorized
        else
          session[:user_id] = user.id
          render json: { user: user_json(user) }, status: :created
        end
      end

      def destroy
        session.delete(:user_id)
        head :no_content
      end

      private

      def authenticated_user
        user = User.find_by(email: session_params[:email].to_s.strip.downcase)
        user if user&.authenticate(session_params[:password])
      end

      def session_params
        params.permit(:email, :password)
      end
    end
  end
end
