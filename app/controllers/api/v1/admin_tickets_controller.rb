# frozen_string_literal: true

module Api
  module V1
    class AdminTicketsController < BaseController
      before_action :require_admin!

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100
      EQUALITY_FILTERS = %i[status priority customer_id].freeze

      def index
        scope = filtered_scope
        tickets = scope.includes(*ticket_includes)
                       .order(created_at: :desc)
                       .limit(per_page)
                       .offset((page - 1) * per_page)

        render json: {
          tickets: TicketBlueprint.render_as_hash(tickets),
          meta: pagination_meta(scope.count)
        }
      end

      private

      def filtered_scope
        scope = apply_equality_filters(Ticket.all)
        scope = apply_assignee_filter(scope)
        apply_search(scope)
      end

      def apply_equality_filters(scope)
        EQUALITY_FILTERS.reduce(scope) do |result, key|
          params[key].present? ? result.where(key => params[key]) : result
        end
      end

      def apply_assignee_filter(scope)
        return scope if params[:assignee_id].blank?

        return scope.where(assignee_id: nil) if params[:assignee_id] == 'unassigned'

        scope.where(assignee_id: params[:assignee_id])
      end

      def apply_search(scope)
        query = params[:q].to_s.strip
        return scope if query.blank?

        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
        scope.where('title ILIKE :q OR description ILIKE :q', q: pattern)
      end

      def pagination_meta(total_count)
        {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        }
      end

      def page
        [params[:page].to_i, 1].max
      end

      def per_page
        requested = params[:per_page].to_i
        requested = DEFAULT_PER_PAGE if requested <= 0
        [requested, MAX_PER_PAGE].min
      end

      def ticket_includes
        [:customer, :assignee, :comments, :tags, { attachments_attachments: :blob }]
      end
    end
  end
end
