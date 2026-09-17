# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_user if respond_to?(:helper_method)
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
    session.delete(:user_id) if @current_user&.disabled?
    @current_user = nil if @current_user&.disabled?
    @current_user
  end

  def require_login
    return if current_user

    render json: { error: I18n.t('api.errors.unauthorized') }, status: :unauthorized
  end

  def require_admin!
    return if current_user&.admin?

    render json: { error: I18n.t('api.errors.forbidden') }, status: :forbidden
  end

  def user_json(user)
    UserBlueprint.render_as_hash(user)
  end
end
