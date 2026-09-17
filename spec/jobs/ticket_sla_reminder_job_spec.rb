# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSlaReminderJob, type: :job do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:admin) { User.create!(email: 'admin@helpdesk.local', password: 'password123', role: :admin) }
  let!(:ticket) { Ticket.create!(title: 'SLA test', description: 'Open', customer: customer, priority: :high) }

  it 'emails admins when the ticket is still open and unassigned' do
    perform_enqueued_jobs do
      described_class.perform_now(ticket.id)
    end

    expect(ActionMailer::Base.deliveries.map(&:to)).to eq([[admin.email]])
    expect(ActionMailer::Base.deliveries.last.subject).to include('SLA reminder')
  end

  it 'does not send mail when the ticket is closed' do
    ticket.update!(status: :closed)

    expect do
      perform_enqueued_jobs do
        described_class.perform_now(ticket.id)
      end
    end.not_to(change { ActionMailer::Base.deliveries.size })
  end

  it 'emails the assignee when the ticket is assigned' do
    ticket.update!(assignee: admin, status: :in_progress)

    perform_enqueued_jobs do
      described_class.perform_now(ticket.id)
    end

    expect(ActionMailer::Base.deliveries.map(&:to)).to eq([[admin.email]])
  end
end
