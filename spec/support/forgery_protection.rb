# frozen_string_literal: true

module ForgeryProtectionHelpers
  def with_forgery_protection
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
end

RSpec.configure do |config|
  config.include ForgeryProtectionHelpers, type: :request
end
