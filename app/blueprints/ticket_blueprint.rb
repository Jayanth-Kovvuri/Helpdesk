# frozen_string_literal: true

class TicketBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :description, :created_at, :updated_at

  field :status do |ticket|
    {
      code: ticket.status,
      label: I18n.t("ticket.statuses.#{ticket.status}", default: ticket.status.humanize)
    }
  end

  field :priority do |ticket|
    {
      code: ticket.priority,
      label: I18n.t("ticket.priorities.#{ticket.priority}", default: ticket.priority.humanize)
    }
  end

  field :comments_count do |ticket|
    ticket.comments.loaded? ? ticket.comments.size : ticket.comments.count
  end

  field :attachments_count do |ticket|
    if ticket.attachments.loaded?
      ticket.attachments.size
    else
      ticket.attachments.count
    end
  end

  field :tags do |ticket|
    TagBlueprint.render_as_hash(ticket.tags)
  end

  association :customer, blueprint: UserBlueprint
  association :assignee, blueprint: UserBlueprint
end
