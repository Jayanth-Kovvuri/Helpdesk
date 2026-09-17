# frozen_string_literal: true

class TicketMailer < ApplicationMailer
  helper ActionView::Helpers::DateHelper
  helper_method :ticket_url, :status_label, :priority_label

  def ticket_created(ticket, recipient, actor)
    assign_mail_vars(ticket, recipient, actor)

    mail(
      to: recipient.email,
      subject: I18n.t('mailers.ticket.ticket_created.subject', id: ticket.id, title: ticket.title)
    )
  end

  def ticket_assigned(ticket, recipient, actor)
    assign_mail_vars(ticket, recipient, actor)

    mail(
      to: recipient.email,
      subject: I18n.t('mailers.ticket.ticket_assigned.subject', id: ticket.id, title: ticket.title)
    )
  end

  def comment_added(comment, recipient, actor)
    @comment = comment
    @ticket = comment.ticket
    @recipient = recipient
    @actor = actor

    mail(to: recipient.email, subject: comment_added_subject(@ticket))
  end

  def sla_reminder(ticket, recipient)
    @ticket = ticket
    @recipient = recipient
    @sla_wait = TicketSla.reminder_wait(ticket.priority)

    mail(
      to: recipient.email,
      subject: I18n.t('mailers.ticket.sla_reminder.subject', id: ticket.id, title: ticket.title)
    )
  end

  private

  def assign_mail_vars(ticket, recipient, actor)
    @ticket = ticket
    @recipient = recipient
    @actor = actor
  end

  def ticket_url(ticket)
    base = ENV.fetch('HELPDESK_APP_URL', 'http://localhost:5173')
    "#{base.sub(%r{/\z}, '')}/tickets/#{ticket.id}"
  end

  def status_label(ticket)
    I18n.t("ticket.statuses.#{ticket.status}")
  end

  def priority_label(ticket)
    I18n.t("ticket.priorities.#{ticket.priority}")
  end

  def comment_added_subject(ticket)
    I18n.t('mailers.ticket.comment_added.subject', id: ticket.id, title: ticket.title)
  end
end
