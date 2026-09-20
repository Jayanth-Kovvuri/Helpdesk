# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketSlaReminderJob, type: :job do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:admin) { User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin) }
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

  it 'sends a breach email when the ticket is past SLA' do
    ticket.update!(priority: :urgent, created_at: 3.days.ago)

    perform_enqueued_jobs do
      described_class.perform_now(ticket.id)
    end

    expect(ActionMailer::Base.deliveries.last.subject).to include('SLA breached')
    expect(ActionMailer::Base.deliveries.last.body.encoded).to include('breached its SLA')
  end

  it 'sends to NOTIFICATION_EMAIL when configured' do
    ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
    ticket.update!(assignee: admin, status: :in_progress)

    perform_enqueued_jobs do
      described_class.perform_now(ticket.id)
    end

    expect(ActionMailer::Base.deliveries.map(&:to)).to eq([['notify@example.com']])
  ensure
    ENV.delete('NOTIFICATION_EMAIL')
  end
end
