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

  def self.sla_breach(ticket)
    new.sla_breach(ticket)
  end

  def self.notify_sla(ticket, deliver_now: false)
    new.notify_sla(ticket, deliver_now: deliver_now)
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
    deliver_sla(:sla_reminder, ticket)
  end

  def sla_breach(ticket)
    deliver_sla(:sla_breach, ticket)
  end

  def notify_sla(ticket, deliver_now: false)
    mail_action = TicketSla.state(ticket) == :breached ? :sla_breach : :sla_reminder
    deliver_sla(mail_action, ticket, deliver_now: deliver_now)
  end

  private

  def deliver_sla(mail_action, ticket, deliver_now: false)
    sla_recipients(ticket).each do |recipient|
      mail = TicketMailer.public_send(mail_action, ticket, recipient)
      deliver_now ? mail.deliver_now : mail.deliver_later
    end
  end

  def sla_recipients(ticket)
    return [sla_context_user(ticket)] if ENV['NOTIFICATION_EMAIL'].present?

    sla_reminder_recipients(ticket)
  end

  def sla_context_user(ticket)
    ticket.assignee || User.admin.order(:id).first || ticket.customer
  end

  def sla_reminder_recipients(ticket)
    return [ticket.assignee] if ticket.assignee.present?

    User.admin.to_a
  end

  def deliver(mail_action, ticket, recipient, actor)
    TicketMailer.public_send(mail_action, ticket, recipient, actor).deliver_later
  end
end
