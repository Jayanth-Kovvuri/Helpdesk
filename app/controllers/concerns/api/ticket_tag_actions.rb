# frozen_string_literal: true

module Api
  module TicketTagActions
    extend ActiveSupport::Concern

    included do
      include TicketAuthorization

      before_action :set_ticket
      before_action :authorize_ticket_view!
      before_action :authorize_ticket_edit!, only: %i[create destroy]
      before_action :set_ticket_tag, only: :destroy
    end

    def index
      render json: { tags: TagBlueprint.render_as_hash(@ticket.tags.order(:name)) }
    end

    def create
      ticket_tag = attach_tag

      if ticket_tag.persisted? || ticket_tag.save
        render json: { tags: TagBlueprint.render_as_hash(@ticket.tags.reload.order(:name)) },
               status: :created
      else
        render json: { errors: ticket_tag.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @ticket_tag.destroy!
      head :no_content
    end

    private

    def attach_tag
      tag = Tag.find_or_create_by(name: tag_params[:name].to_s.strip.downcase)
      @ticket.ticket_tags.find_or_initialize_by(tag: tag)
    end

    def set_ticket
      @ticket = Ticket.find(params[:ticket_id])
    end

    def set_ticket_tag
      @ticket_tag = @ticket.ticket_tags.find_by!(tag_id: params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
