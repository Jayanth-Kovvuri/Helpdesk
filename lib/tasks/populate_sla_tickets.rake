# frozen_string_literal: true

namespace :tickets do
  desc 'Populate sample tickets with various ages for SLA dashboard testing'
  task populate_sla: :environment do
    admin = User.find_by(role: :admin) || User.create!(
      email: "admin@helpdesk.local",
      name: "Admin User",
      password: "password123",
      role: :admin
    )

    customer = User.find_by(email: 'bob@helpdesk.local') || User.create!(
      email: "bob@helpdesk.local",
      name: "Bob Customer",
      password: "password123",
      role: :customer
    )

    # Define sample tickets with their ages and priorities
    samples = [
      # Urgent tickets
      { title: 'Urgent: System Down', priority: :urgent, hours_ago: 0.5, status: :open },
      { title: 'Urgent: Critical Bug', priority: :urgent, hours_ago: 24, status: :in_progress },
      { title: 'Urgent: Data Loss', priority: :urgent, hours_ago: 48, status: :pending },
      { title: 'Urgent: Breached SLA', priority: :urgent, hours_ago: 72, status: :open },

      # High priority tickets
      { title: 'High: API Timeout', priority: :high, hours_ago: 6, status: :open },
      { title: 'High: Performance Issue', priority: :high, hours_ago: 48, status: :in_progress },
      { title: 'High: Integration Failure', priority: :high, hours_ago: 60, status: :pending },
      { title: 'High: Breached - Old Issue', priority: :high, hours_ago: 84, status: :open },

      # Medium priority tickets
      { title: 'Medium: Feature Request', priority: :medium, hours_ago: 12, status: :open },
      { title: 'Medium: Documentation', priority: :medium, hours_ago: 72, status: :in_progress },
      { title: 'Medium: At Risk', priority: :medium, hours_ago: 100, status: :pending },
      { title: 'Medium: Breached', priority: :medium, hours_ago: 144, status: :open },

      # Low priority tickets
      { title: 'Low: Enhancement', priority: :low, hours_ago: 24, status: :open },
      { title: 'Low: Nice to Have', priority: :low, hours_ago: 120, status: :in_progress },
      { title: 'Low: At Risk', priority: :low, hours_ago: 150, status: :pending },
      { title: 'Low: Breached', priority: :low, hours_ago: 200, status: :open },
    ]

    samples.each do |sample|
      created_time = sample[:hours_ago].hours.ago

      ticket = Ticket.create!(
        title: sample[:title],
        description: "Sample ticket for SLA testing created #{created_time.strftime('%Y-%m-%d %H:%M:%S')}",
        priority: sample[:priority],
        status: sample[:status],
        customer: customer,
        assignee: admin,
        created_at: created_time,
        updated_at: created_time
      )

      puts "Created #{sample[:priority].upcase} ticket: #{ticket.title} (#{sample[:hours_ago]} hours ago)"
    end

    puts "\n✅ SLA test data populated successfully!"
    puts "\nSLA Thresholds:"
    puts "  Urgent: 2 days (at risk: 1 day)"
    puts "  High: 3 days (at risk: 2 days)"
    puts "  Medium: 5 days (at risk: 3 days)"
    puts "  Low: 7 days (at risk: 5 days)"
  end
end
