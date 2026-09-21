# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketNotifications do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:admin) { User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin) }
  let!(:other_admin) { User.create!(email: 'admin2@helpdesk.local', name: 'admin2@helpdesk.local', password: 'password123', role: :admin) }

  around do |example|
    @previous_notification_email = ENV['NOTIFICATION_EMAIL']
    ENV.delete('NOTIFICATION_EMAIL')
    example.run
  ensure
    if @previous_notification_email.nil?
      ENV.delete('NOTIFICATION_EMAIL')
    else
      ENV['NOTIFICATION_EMAIL'] = @previous_notification_email
    end
  end

  describe '.ticket_created' do
    it 'notifies all admins when a customer creates a ticket' do
      ticket = Ticket.create!(title: 'Help', description: 'Need help', customer: customer)

      expect do
        perform_enqueued_jobs do
          described_class.ticket_created(ticket, actor: customer)
        end
      end.to change { ActionMailer::Base.deliveries.size }.by(2)

      recipients = ActionMailer::Base.deliveries.flat_map(&:to)
      expect(recipients).to contain_exactly(admin.email, other_admin.email)
    end

    it 'sends one mail to NOTIFICATION_EMAIL when a customer creates a ticket' do
      ticket = Ticket.create!(title: 'Help', description: 'Need help', customer: customer)

      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      expect do
        perform_enqueued_jobs do
          described_class.ticket_created(ticket, actor: customer)
        end
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(ActionMailer::Base.deliveries.last.to).to eq(['notify@example.com'])
    end

    it 'notifies assignee at NOTIFICATION_EMAIL when set on create' do
      ticket = Ticket.create!(
        title: 'Help', description: 'Need help', customer: customer, assignee: other_admin
      )

      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      described_class.ticket_created(ticket, actor: customer)

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq(['notify@example.com'])
    end

    it 'notifies default main admin at NOTIFICATION_EMAIL when admin creates without assignee' do
      ticket = Ticket.create!(title: 'Help', description: 'Need help', customer: customer)

      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      described_class.ticket_created(ticket, actor: admin)

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq(['notify@example.com'])
    end

    it 'notifies the customer when an admin creates a ticket for them' do
      ticket = Ticket.create!(title: 'Help', description: 'Need help', customer: customer)

      perform_enqueued_jobs do
        described_class.ticket_created(ticket, actor: admin)
      end

      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([[customer.email]])
    end
  end

  describe '.ticket_assigned' do
    it 'skips email when the assignee is the actor' do
      ticket = Ticket.create!(title: 'Help', description: 'Need help', customer: customer, assignee: admin)

      expect do
        perform_enqueued_jobs do
          described_class.ticket_assigned(ticket, actor: admin)
        end
      end.not_to(change { ActionMailer::Base.deliveries.size })
    end

    it 'emails the assignee when someone else assigns the ticket' do
      ticket = Ticket.create!(title: 'Help', description: 'Need help', customer: customer, assignee: other_admin)

      perform_enqueued_jobs do
        described_class.ticket_assigned(ticket, actor: admin)
      end

      expect(ActionMailer::Base.deliveries.last.to).to eq([other_admin.email])
    end

    it 'sends to NOTIFICATION_EMAIL when configured' do
      ticket = Ticket.create!(title: 'Help', description: 'Need help', customer: customer, assignee: other_admin)

      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      perform_enqueued_jobs do
        described_class.ticket_assigned(ticket, actor: admin)
      end

      expect(ActionMailer::Base.deliveries.last.to).to eq(['notify@example.com'])
    end
  end

  describe '.status_changed' do
    let(:ticket) { Ticket.create!(title: 'Help', description: 'Need help', customer: customer, assignee: admin) }

    it 'sends to NOTIFICATION_EMAIL when configured' do
      ENV['NOTIFICATION_EMAIL'] = 'notify@example.com'
      described_class.status_changed(ticket, actor: customer, previous_status: 'open')

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq(['notify@example.com'])
    end

    it 'notifies customer and assignee when override is unset' do
      ticket.update!(status: :in_progress)
      expect do
        perform_enqueued_jobs do
          described_class.status_changed(ticket.reload, actor: admin, previous_status: 'open')
        end
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(ActionMailer::Base.deliveries.last.to).to eq([customer.email])
    end
  end

  describe '.comment_added' do
    let(:ticket) { Ticket.create!(title: 'Help', description: 'Need help', customer: customer, assignee: admin) }

    it 'notifies other participants but not the author' do
      comment = Comment.create!(body: 'Update', ticket: ticket, user: customer)

      perform_enqueued_jobs do
        described_class.comment_added(comment, actor: customer)
      end

      expect(ActionMailer::Base.deliveries.map(&:to)).to eq([[admin.email]])
    end
  end
end
