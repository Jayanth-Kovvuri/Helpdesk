# frozen_string_literal: true

class UserPrivacy
  class << self
    def export(user)
      new(user).export
    end

    def destroy_account!(user)
      new(user).destroy_account!
    end
  end

  def initialize(user)
    @user = user
  end

  def export
    {
      exported_at: Time.current.iso8601,
      format: 'helpdesk-gdpr-export-v1',
      user: UserBlueprint.render_as_hash(@user),
      tickets: export_tickets,
      comments_authored: export_authored_comments
    }
  end

  def destroy_account!
    @user.destroy!
  end

  private

  def export_tickets
    tickets = @user.tickets.includes(:comments, :assignee, attachments_attachments: :blob).order(:id)
    tickets.map do |ticket|
      TicketBlueprint.render_as_hash(ticket).merge(
        comments: CommentBlueprint.render_as_hash(ticket.comments.order(:created_at)),
        attachments: attachment_metadata(ticket)
      )
    end
  end

  def export_authored_comments
    comments = @user.comments.includes(:ticket).order(:created_at)
    comments.map do |comment|
      CommentBlueprint.render_as_hash(comment).merge(
        ticket_id: comment.ticket_id,
        ticket_title: comment.ticket.title
      )
    end
  end

  def attachment_metadata(ticket)
    ticket.attachments.map do |attachment|
      {
        id: attachment.id,
        filename: attachment.filename.to_s,
        content_type: attachment.content_type,
        byte_size: attachment.byte_size
      }
    end
  end
end
