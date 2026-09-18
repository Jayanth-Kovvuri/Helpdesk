# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  searchkick word_middle: %i[name email],
             filterable: %i[role disabled],
             callbacks: false

  enum role: { customer: 0, admin: 1 }

  has_many :tickets, foreign_key: :customer_id, dependent: :destroy, inverse_of: :customer
  has_many :assigned_tickets, class_name: 'Ticket', foreign_key: :assignee_id,
                              dependent: :nullify, inverse_of: :assignee
  has_many :comments, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :role, presence: true

  after_commit :sync_search_index, on: %i[create update]

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

  def search_data
    {
      name: name,
      email: email,
      role: role,
      disabled: disabled?
    }
  end

  def sync_search_index
    return unless UserSearch.use_elasticsearch?

    reindex
  rescue StandardError => e
    Rails.logger.warn("User search reindex failed for ##{id}: #{e.message}")
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
