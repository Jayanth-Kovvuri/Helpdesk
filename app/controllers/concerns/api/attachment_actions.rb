# frozen_string_literal: true

module Api
  module AttachmentActions
    extend ActiveSupport::Concern

    included do
      include TicketAuthorization

      before_action :set_ticket
      before_action :authorize_ticket_view!
      before_action :set_attachment, only: :destroy
      before_action :authorize_attachment_manage!, only: :destroy
    end

    def index
      attachments = @ticket.attachments.includes(:blob)
      render json: AttachmentBlueprint.render(attachments, **attachment_blueprint_options.merge(root: :attachments))
    end

    def create
      file = attachment_params[:file]
      return invalid_attachment unless Ticket.allowed_upload?(file)

      attach_upload!(file)
      @ticket.bump_cache_timestamp!
      render_attachment(@ticket.attachments.last, status: :created)
    end

    def destroy
      @attachment.purge
      @ticket.bump_cache_timestamp!
      head :no_content
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def set_attachment
      @attachment = @ticket.attachments.find(params[:id])
    end

    def attachment_params
      params.require(:attachment).permit(:file)
    end

    def authorize_attachment_manage!
      return if attachment_manageable?(@attachment)

      render json: { error: I18n.t('api.errors.forbidden') }, status: :forbidden
    end

    def attachment_manageable?(attachment)
      return true if current_user.admin?

      attachment.metadata['user_id'].to_i == current_user.id
    end

    def invalid_attachment
      render json: { error: I18n.t('api.errors.invalid_attachment') }, status: :unprocessable_entity
    end

    def attach_upload!(file)
      @ticket.attachments.attach(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type,
        metadata: { user_id: current_user.id }
      )
    end

    def render_attachment(attachment, status: :ok)
      render json: AttachmentBlueprint.render(
        attachment,
        **attachment_blueprint_options.merge(root: :attachment)
      ), status: status
    end

    def attachment_blueprint_options
      {
        host: request.host_with_port,
        protocol: request.protocol.chomp('://')
      }
    end
  end
end
