# frozen_string_literal: true

namespace :tickets do
  desc 'Create 25 demo tickets (all statuses, SLA states, assignees) for SLA dashboards using existing users'
  task populate_sla_demo: :environment do
    admins = User.where(role: :admin).order(:id).to_a
    customers = User.where(role: :customer).order(:id).to_a

    if admins.empty?
      abort 'No admin users found. Run db:seed first.'
    end
    if customers.empty?
      abort 'No customer users found. Run db:seed first.'
    end

    primary_admin = admins.first
    customer = customers.first
    assignee_pool = admins.cycle

    removed = Ticket.where('title LIKE ?', '[SLA Demo]%').destroy_all.size
    puts "Removed #{removed} previous [SLA Demo] tickets." if removed.positive?

    # Active tickets (operational tab): open / in_progress / pending
    active_samples = [
      { title: '[SLA Demo] Urgent — on track', priority: :urgent, status: :open, created_days_ago: 0.5, assignee: true },
      { title: '[SLA Demo] High — on track', priority: :high, status: :in_progress, created_days_ago: 1.5, assignee: true },
      { title: '[SLA Demo] High — at risk', priority: :high, status: :pending, created_days_ago: 2.5, assignee: true },
      { title: '[SLA Demo] Medium — on track', priority: :medium, status: :open, created_days_ago: 2, assignee: true },
      { title: '[SLA Demo] Medium — at risk', priority: :medium, status: :in_progress, created_days_ago: 4, assignee: false },
      { title: '[SLA Demo] Low — on track', priority: :low, status: :pending, created_days_ago: 3, assignee: true },
      { title: '[SLA Demo] Low — at risk', priority: :low, status: :open, created_days_ago: 6, assignee: true },
      { title: '[SLA Demo] Urgent — breached', priority: :urgent, status: :open, created_days_ago: 3, assignee: true },
      { title: '[SLA Demo] High — breached', priority: :high, status: :in_progress, created_days_ago: 4, assignee: true },
      { title: '[SLA Demo] Medium — breached', priority: :medium, status: :pending, created_days_ago: 6, assignee: false },
      { title: '[SLA Demo] Low — breached', priority: :low, status: :open, created_days_ago: 8, assignee: true },
      { title: '[SLA Demo] Urgent — at risk (assigned)', priority: :urgent, status: :in_progress, created_days_ago: 1.2, assignee: true }
    ]

    # Closed in last 30 days (analytics tab): resolved / closed, mix of compliant vs SLA breach at close
    closed_samples = [
      { title: '[SLA Demo] Closed — urgent breach', priority: :urgent, status: :closed, created_days_ago: 10, closed_days_ago: 1 },
      { title: '[SLA Demo] Resolved — high breach', priority: :high, status: :resolved, created_days_ago: 12, closed_days_ago: 2 },
      { title: '[SLA Demo] Closed — medium compliant', priority: :medium, status: :closed, created_days_ago: 6, closed_days_ago: 2 },
      { title: '[SLA Demo] Resolved — low compliant', priority: :low, status: :resolved, created_days_ago: 8, closed_days_ago: 3 },
      { title: '[SLA Demo] Closed — high compliant', priority: :high, status: :closed, created_days_ago: 5, closed_days_ago: 1 },
      { title: '[SLA Demo] Resolved — medium compliant (fast)', priority: :medium, status: :resolved, created_days_ago: 4, closed_days_ago: 1 },
      { title: '[SLA Demo] Closed — urgent compliant', priority: :urgent, status: :closed, created_days_ago: 3, closed_days_ago: 1 },
      { title: '[SLA Demo] Resolved — low compliant (week)', priority: :low, status: :resolved, created_days_ago: 12, closed_days_ago: 5 },
      { title: '[SLA Demo] Closed — medium breach (slow)', priority: :medium, status: :closed, created_days_ago: 14, closed_days_ago: 3 },
      { title: '[SLA Demo] Resolved — high breach (old)', priority: :high, status: :resolved, created_days_ago: 18, closed_days_ago: 4 },
      { title: '[SLA Demo] Closed — low compliant (short)', priority: :low, status: :closed, created_days_ago: 9, closed_days_ago: 6 },
      { title: '[SLA Demo] Resolved — urgent breach (edge)', priority: :urgent, status: :resolved, created_days_ago: 6, closed_days_ago: 2 },
      { title: '[SLA Demo] Closed — low breach (long)', priority: :low, status: :closed, created_days_ago: 22, closed_days_ago: 5 }
    ]

    create_ticket = lambda do |sample, assignee|
      created_at = sample[:created_days_ago].days.ago
      updated_at = sample[:closed_days_ago] ? sample[:closed_days_ago].days.ago : created_at
      cust = customers.sample

      ticket = Ticket.new(
        title: sample[:title],
        description: 'Demo data for SLA operational and analytics dashboards.',
        priority: sample[:priority],
        status: sample[:status],
        customer: cust,
        assignee: assignee,
        created_at: created_at,
        updated_at: updated_at
      )
      ticket.save!(validate: true)
      ticket
    end

    Ticket.skip_callback(:commit, :after, :bust_sla_dashboard_cache_if_needed)
    begin
    active_samples.each do |sample|
      assignee = sample[:assignee] ? assignee_pool.next : nil
      ticket = create_ticket.call(sample, assignee)
      puts "Active #{ticket.status} / #{ticket.priority}: #{ticket.title}"
    end

    closed_samples.each do |sample|
      assignee = assignee_pool.next
      ticket = create_ticket.call(sample, assignee)
      puts "Closed #{ticket.status} / #{ticket.priority}: #{ticket.title}"
    end
    ensure
      Ticket.set_callback(:commit, :after, :bust_sla_dashboard_cache_if_needed)
    end

    TicketSlaDashboard.bust_cache!
    TicketSlaAnalytics.bust_cache!

    puts "\n✅ Created #{active_samples.size + closed_samples.size} [SLA Demo] tickets."
    puts "   Customers: #{customers.map(&:email).join(', ')}"
    puts "   Assignees: #{admins.map(&:email).join(', ')} (+ unassigned on some active tickets)"
    puts "\nRefresh the SLA dashboard (Operational + Statistics tabs)."
  end
end
