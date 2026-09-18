# frozen_string_literal: true

module Api
  module CommentActions
    extend ActiveSupport::Concern

    included do
      include TicketAuthorization

      before_action :set_ticket
      before_action :authorize_ticket_view!
      before_action :set_comment, only: :destroy
      before_action :authorize_comment_manage!, only: :destroy
    end

    def index
      comments = @ticket.comments.includes(:user).order(created_at: :asc)

      render json: comment_blueprint.render(
        comments,
        root: :comments,
        **comment_render_options
      )
    end

    def create
      upload = comment_upload_file
      if upload.present? && !Ticket.allowed_upload?(upload)
        return render json: { error: I18n.t('api.errors.invalid_attachment') }, status: :unprocessable_entity
      end

      comment = @ticket.comments.build(comment_body_params.merge(user: current_user))

      if comment.save
        attach_comment_file!(comment, upload) if upload.present?
        @ticket.attachments.reload if upload.present?
        TicketNotifications.comment_added(comment, actor: current_user)
        render json: comment_blueprint.render(comment.reload, root: :comment, **comment_render_options),
               status: :created
      else
        render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @comment.destroy!
      head :no_content
    end

    private

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def set_comment
      @comment = @ticket.comments.find(params[:id])
    end

    def comment_body_params
      params.require(:comment).permit(:body)
    end

    def comment_upload_file
      file = params.dig(:comment, :file)
      file if file.is_a?(ActionDispatch::Http::UploadedFile)
    end

    def attach_comment_file!(comment, file)
      @ticket.attachments.attach(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type,
        metadata: { user_id: current_user.id, comment_id: comment.id }
      )
      @ticket.bump_cache_timestamp!
    end

    def comment_render_options
      {
        host: request.host_with_port,
        protocol: request.protocol.chomp('://'),
        attachments_by_comment_id: attachments_by_comment_id(@ticket)
      }
    end

    def attachments_by_comment_id(ticket)
      ticket.attachments.includes(:blob).each_with_object({}) do |attachment, grouped|
        comment_id = attachment.metadata['comment_id'].to_i
        next if comment_id.zero?

        grouped[comment_id] ||= []
        grouped[comment_id] << attachment
      end
    end

    def authorize_comment_manage!
      return if @comment.manageable_by?(current_user)

      render json: { error: I18n.t('api.errors.forbidden') }, status: :forbidden
    end

    def comment_blueprint
      raise NotImplementedError
    end
  end
end
