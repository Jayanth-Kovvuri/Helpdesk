# frozen_string_literal: true

class TicketTag < ApplicationRecord
  belongs_to :ticket, touch: true
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :ticket_id }

  after_commit :refresh_ticket_search_index, on: %i[create destroy]

  private

  def refresh_ticket_search_index
    ticket.sync_search_index
  end
end
