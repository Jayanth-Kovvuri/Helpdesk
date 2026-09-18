# frozen_string_literal: true

module Api
  module TicketActions
    extend ActiveSupport::Concern

    included do
      include TicketAuthorization

      before_action :set_ticket, only: %i[show update destroy]
      before_action :authorize_ticket_view!, only: %i[show update destroy]
      before_action :authorize_ticket_edit!, only: %i[update]
      before_action :require_admin!, only: %i[destroy]
    end

    def index
      query = params[:q].to_s.strip
      json =
        if query.length >= TicketSearch::MIN_QUERY_LENGTH
          TicketResponseCache.fetch_search(
            current_user,
            query,
            filter: params[:filter],
            status: params[:status],
            priority: params[:priority]
          ) do
            ticket_blueprint.render(tickets_for_query(query), root: :tickets)
          end
        else
          TicketResponseCache.fetch_index(current_user) do
            ticket_blueprint.render(ticket_scope, root: :tickets)
          end
        end
      render json: json
    end

    def search
      query = params[:q]
      if query.blank?
        return render json: { error: I18n.t('api.errors.query_required') }, status: :bad_request
      end

      json = TicketResponseCache.fetch_search(
        current_user,
        query,
        filter: params[:filter],
        status: params[:status],
        priority: params[:priority]
      ) do
        ticket_blueprint.render(tickets_for_query(query), root: :tickets)
      end
      render json: json
    end

    def show
      json = TicketResponseCache.fetch_show(@ticket) do
        ticket_blueprint.render(@ticket, root: :ticket)
      end
      render json: json
    end

    def create
      ticket = build_ticket_for_create
      attachments = ticket_create_params[:attachments]

      if ticket.save
        attach_files_to_ticket(ticket, attachments)
        notify_ticket_created(ticket)
        render json: ticket_blueprint.render(ticket.reload, root: :ticket), status: :created
      else
        render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @ticket.update(ticket_update_params)
        notify_ticket_assigned_if_changed
        render json: ticket_blueprint.render(@ticket.reload, root: :ticket)
      else
        render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @ticket.destroy!
      head :no_content
    end

    private

    def ticket_scope
      apply_ticket_list_filter(Ticket.visible_to(current_user))
        .includes(*ticket_includes)
        .order(created_at: :desc)
    end

    def apply_ticket_list_filter(scope)
      case params[:filter]
      when 'raised'
        scope.where(customer_id: current_user.id)
      when 'assigned'
        scope.where(assignee_id: current_user.id)
      else
        scope
      end
    end

    def tickets_for_query(query)
      TicketSearch.call(
        user: current_user,
        query: query,
        filter: params[:filter],
        status: params[:status],
        priority: params[:priority]
      )
    end

    def ticket_includes
      [:customer, :assignee, :comments, :tags, { attachments_attachments: :blob }]
    end

    def set_ticket
      @ticket = Ticket.includes(*ticket_includes).find(params[:id])
    end

    def build_ticket_for_create
      Ticket.new(customer_ticket_attributes)
    end

    def customer_ticket_attributes
      permitted = ticket_create_params
      assignee = find_assignee(permitted[:assignee_id])

      {
        title: permitted[:title],
        description: permitted[:description],
        priority: permitted[:priority] || :medium,
        customer: current_user,
        status: :open,
        assignee: assignee
      }
    end

    def find_assignee(assignee_id)
      # If assignee is specified by admin, use it; otherwise auto-assign to first admin
      if assignee_id.present? && current_user.admin?
        User.find(assignee_id)
      else
        User.where(role: :admin).first
      end
    end

    def ticket_create_params
      permitted = %i[title description status priority assignee_id]
      permitted << :customer_id if current_user.admin?
      permitted << { attachments: [] }

      params.require(:ticket).permit(permitted)
    end

    def ticket_update_params
      if current_user.admin?
        params.require(:ticket).permit(
          :title, :description, :status, :priority, :assignee_id, :customer_id
        )
      else
        params.require(:ticket).permit(:title, :description)
      end
    end

    def ticket_blueprint
      raise NotImplementedError
    end

    def notify_ticket_created(ticket)
      TicketNotifications.ticket_created(ticket, actor: current_user)
      TicketSlaScheduler.schedule_reminder(ticket)
      return if ticket.assignee_id.blank?

      TicketNotifications.ticket_assigned(ticket, actor: current_user)
    end

    def notify_ticket_assigned_if_changed
      return unless @ticket.saved_change_to_assignee_id?
      return if @ticket.assignee_id.blank?

      TicketNotifications.ticket_assigned(@ticket, actor: current_user)
    end

    def attach_files_to_ticket(ticket, files)
      return if files.blank?

      Array(files).each do |file|
        next unless Ticket.allowed_upload?(file)

        ticket.attachments.attach(
          io: file,
          filename: file.original_filename,
          content_type: file.content_type,
          metadata: { user_id: current_user.id }
        )
      end
    end
  end
end
