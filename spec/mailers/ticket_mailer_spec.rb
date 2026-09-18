# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketMailer, type: :mailer do
  let(:customer) { User.create!(email: 'customer@helpdesk.local', name: 'customer@helpdesk.local', password: 'password123', role: :customer) }
  let(:admin) { User.create!(email: 'admin@helpdesk.local', name: 'admin@helpdesk.local', password: 'password123', role: :admin) }
  let(:ticket) do
    Ticket.create!(title: 'VPN issue', description: 'Cannot connect', customer: customer, assignee: admin)
  end

  describe '#ticket_created' do
    let(:mail) { described_class.ticket_created(ticket, admin, customer) }

    it 'sends to the recipient with a localized subject' do
      expect(mail.to).to eq([admin.email])
      expect(mail.subject).to include("New ticket ##{ticket.id}")
      expect(mail.body.encoded).to include('VPN issue')
    end
  end

  describe '#ticket_assigned' do
    let(:mail) { described_class.ticket_assigned(ticket, admin, admin) }

    it 'sends assignment details to the assignee' do
      expect(mail.to).to eq([admin.email])
      expect(mail.subject).to include('Assigned')
      expect(mail.body.encoded).to include('You were assigned')
    end
  end

  describe '#comment_added' do
    let(:comment) { Comment.create!(body: 'Checking logs', ticket: ticket, user: admin) }
    let(:mail) { described_class.comment_added(comment, customer, admin) }

    it 'includes the comment body' do
      expect(mail.to).to eq([customer.email])
      expect(mail.subject).to include('New comment')
      expect(mail.body.encoded).to include('Checking logs')
    end
  end
end
