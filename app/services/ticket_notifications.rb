# frozen_string_literal: true

class TicketNotifications
  def self.ticket_created(ticket, actor:)
    new.ticket_created(ticket, actor: actor)
  end

  def self.ticket_assigned(ticket, actor:)
    new.ticket_assigned(ticket, actor: actor)
  end

  def self.comment_added(comment, actor:)
    new.comment_added(comment, actor: actor)
  end

  def self.sla_reminder(ticket)
    new.sla_reminder(ticket)
  end

  def ticket_created(ticket, actor:)
    if actor.admin?
      deliver(:ticket_created, ticket, ticket.customer, actor)
    else
      User.admin.find_each do |admin|
        deliver(:ticket_created, ticket, admin, actor)
      end
    end
  end

  def ticket_assigned(ticket, actor:)
    assignee = ticket.assignee
    return if assignee.blank?
    return if assignee.id == actor.id

    deliver(:ticket_assigned, ticket, assignee, actor)
  end

  def comment_added(comment, actor:)
    ticket = comment.ticket
    recipients = [ticket.customer, ticket.assignee].compact.uniq
    recipients.reject! { |user| user.id == actor.id }

    recipients.each do |recipient|
      TicketMailer.comment_added(comment, recipient, actor).deliver_later
    end
  end

  def sla_reminder(ticket)
    recipients = sla_reminder_recipients(ticket)
    recipients.each do |recipient|
      TicketMailer.sla_reminder(ticket, recipient).deliver_later
    end
  end

  private

  def sla_reminder_recipients(ticket)
    return [ticket.assignee] if ticket.assignee.present?

    User.admin.to_a
  end

  def deliver(mail_action, ticket, recipient, actor)
    TicketMailer.public_send(mail_action, ticket, recipient, actor).deliver_later
  end
end
