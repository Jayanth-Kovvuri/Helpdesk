# frozen_string_literal: true

module LocaleSwitchable
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    I18n.locale = resolved_locale
  end

  def resolved_locale
    locale = params[:locale].presence || header_locale
    locale = locale.to_s.downcase.to_sym
    return locale if I18n.available_locales.include?(locale)

    I18n.default_locale
  end

  def header_locale
    accept = request.headers['Accept-Language']
    return if accept.blank?

    accept.scan(/[a-z]{2}(?=-|,|;|$)/i).map(&:downcase).find do |code|
      I18n.available_locales.map(&:to_s).include?(code)
    end
  end
end
