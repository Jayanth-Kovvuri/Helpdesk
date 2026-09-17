# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Application' do
  it 'loads the Helpdesk Rails application' do
    expect(Rails.application.class.parent_name).to eq('Helpdesk')
  end

  it 'uses the test environment' do
    expect(Rails.env).to eq('test')
  end
end
