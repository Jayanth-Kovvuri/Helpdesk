# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSlaScheduler do
  let(:customer) { User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let(:ticket) { Ticket.create!(title: 'Schedule me', description: 'Details', customer: customer, priority: :medium) }

  it 'enqueues a delayed SLA reminder job' do
    expect do
      described_class.schedule_reminder(ticket)
    end.to have_enqueued_job(TicketSlaReminderJob)
      .with(ticket.id)
      .on_queue('default')
  end
end
