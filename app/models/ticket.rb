# frozen_string_literal: true

class Ticket < ApplicationRecord
  include AttachmentValidations

  searchkick word_middle: %i[title description comment_text tag_names],
             callbacks: false

  belongs_to :customer, class_name: 'User'
  belongs_to :assignee, class_name: 'User', optional: true

  has_many :comments, dependent: :destroy
  has_many :ticket_tags, dependent: :destroy
  has_many :tags, through: :ticket_tags
  has_many_attached :attachments

  enum status: { open: 0, in_progress: 1, pending: 2, resolved: 3, closed: 4 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  validates :title, presence: true
  validates :status, presence: true
  validates :priority, presence: true
  validate :assignee_must_be_admin, if: -> { assignee_id.present? }

  after_commit :sync_search_index, on: %i[create update]
  after_commit :bust_sla_dashboard_cache_if_needed

  scope :visible_to, lambda { |user|
    if user.admin?
      all
    else
      where(customer_id: user.id)
    end
  }

  def visible_to?(user)
    user.admin? || customer_id == user.id
  end

  def editable_by?(user)
    return true if user.admin?

    customer_id == user.id && !closed?
  end

  def search_data
    {
      title: title,
      description: description,
      comment_text: comments.pluck(:body).join("\n"),
      tag_names: tags.pluck(:name).join(' '),
      customer_id: customer_id,
      assignee_id: assignee_id,
      status: status,
      priority: priority,
      created_at: created_at
    }
  end

  def sync_search_index
    return unless TicketSearch.use_elasticsearch?

    reindex
  rescue StandardError => e
    Rails.logger.warn("Ticket search reindex failed for ##{id}: #{e.message}")
  end

  def bump_cache_timestamp!
    touch # rubocop:disable Rails/SkipsModelValidations -- cache key invalidation only
  end

  private

  def assignee_must_be_admin
    return if assignee&.admin?

    errors.add(:assignee, 'must be an admin user')
  end

  def bust_sla_dashboard_cache_if_needed
    sla_relevant = %w[id status priority created_at]
    return unless destroyed? || (previous_changes.keys & sla_relevant).any?

    TicketSlaDashboard.bust_cache!
    TicketSlaAnalytics.bust_cache!
  end
end
