# frozen_string_literal: true

class MailRecipient
  ROUTED_TYPES = %i[ticket_assigned sla_reminder sla_breach].freeze

  class << self
    def delivery_address(notification_type, default_email)
      type = notification_type.to_sym
      override = ENV['NOTIFICATION_EMAIL'].presence
      return default_email unless override && ROUTED_TYPES.include?(type)

      override
    end
  end
end
