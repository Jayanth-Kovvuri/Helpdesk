# frozen_string_literal: true

module Api
  module V1
    class MeController < BaseController
      def show
        render json: { user: user_json(current_user) }
      end

      def update
        return render_invalid_current_password unless current_password_valid?

        if current_user.update(password: password_params[:new_password])
          render json: { user: user_json(current_user) }
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        UserPrivacy.destroy_account!(current_user)
        reset_session
        head :no_content
      end

      private

      def current_password_valid?
        current_user.authenticate(password_params[:current_password].to_s)
      end

      def render_invalid_current_password
        render json: { error: I18n.t('api.errors.invalid_current_password') }, status: :unprocessable_entity
      end

      def password_params
        params.permit(:current_password, :new_password)
      end
    end
  end
end
