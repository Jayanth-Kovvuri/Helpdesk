# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :ticket, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 10_000 }

  before_validation :sanitize_body

  after_commit :refresh_ticket_search_index, on: %i[create update destroy]

  def authored_by?(user)
    user_id == user.id
  end

  def manageable_by?(user)
    user.admin? || authored_by?(user)
  end

  private

  def refresh_ticket_search_index
    ticket.sync_search_index
  end

  def sanitize_body
    self.body = ActionController::Base.helpers.strip_tags(body.to_s).strip
  end
end
