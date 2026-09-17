# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :require_admin!
      before_action :set_user, only: :update

      def index
        render json: { users: UserBlueprint.render_as_hash(User.order(:email)) }
      end

      def create
        user = User.new(user_params)

        if user.save
          render json: { user: user_json(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        return render_cannot_disable_self if disabling_self?

        toggle_disabled!
        render json: { user: user_json(@user) }
      end

      private

      def toggle_disabled!
        disabled_params[:disabled] ? @user.disable! : @user.enable!
      end

      def disabling_self?
        disabled_params[:disabled] && @user.id == current_user.id
      end

      def render_cannot_disable_self
        render json: { error: I18n.t('api.errors.cannot_disable_self') }, status: :unprocessable_entity
      end

      def set_user
        @user = User.find(params[:id])
      end

      def disabled_params
        params.permit(:disabled).tap { |p| p[:disabled] = ActiveModel::Type::Boolean.new.cast(p[:disabled]) }
      end

      def user_params
        params.permit(:email, :password, :role)
      end
    end
  end
end
