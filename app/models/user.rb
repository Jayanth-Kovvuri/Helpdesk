# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  enum role: { customer: 0, admin: 1 }

  has_many :tickets, foreign_key: :customer_id, dependent: :destroy, inverse_of: :customer
  has_many :assigned_tickets, class_name: 'Ticket', foreign_key: :assignee_id,
                              dependent: :nullify, inverse_of: :assignee
  has_many :comments, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :role, presence: true

  before_validation :normalize_email

  def disabled?
    disabled_at.present?
  end

  def disable!
    update!(disabled_at: Time.current)
  end

  def enable!
    update!(disabled_at: nil)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
