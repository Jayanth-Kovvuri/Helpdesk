# frozen_string_literal: true

password = ENV.fetch('SEED_USER_PASSWORD', 'password123')

admin = User.find_or_initialize_by(email: 'admin@helpdesk.local')
admin.assign_attributes(password: password, password_confirmation: password, role: :admin)
admin.save!

customer = User.find_or_initialize_by(email: 'customer@helpdesk.local')
customer.assign_attributes(password: password, password_confirmation: password, role: :customer)
customer.save!

Rails.logger.debug "Seeded users (password: #{password}):"
Rails.logger.debug "  admin    — #{admin.email}"
Rails.logger.debug "  customer — #{customer.email}"

if Ticket.count.zero?
  Ticket.create!(
    title: 'Sample: Email not syncing',
    description: 'Outlook stopped receiving mail this morning.',
    customer: customer,
    assignee: admin,
    status: :in_progress,
    priority: :high
  )
  Rails.logger.debug 'Seeded 1 sample ticket for customer@helpdesk.local'
end
