# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketNotifications do
  let!(:customer) { User.create!(email: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let!(:admin) { User.create!(email: 'admin@helpdesk.local', password: 'password123', role: :admin) }
  let!(:other_admin) { User.create!(email: 'admin2@helpdesk.local', password: 'password123', role: :admin) }

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
