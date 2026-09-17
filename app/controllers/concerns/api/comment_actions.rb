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

      render json: comment_blueprint.render(comments, root: :comments)
    end

    def create
      comment = @ticket.comments.build(comment_params.merge(user: current_user))

      if comment.save
        TicketNotifications.comment_added(comment, actor: current_user)
        render json: comment_blueprint.render(comment.reload, root: :comment), status: :created
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

    def comment_params
      params.require(:comment).permit(:body)
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
