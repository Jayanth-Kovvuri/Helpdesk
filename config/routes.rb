# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq' if Rails.env.development? || ENV['SIDEKIQ_WEB_USERNAME'].present?

  namespace :api do
    namespace :v1 do
      get :health, to: 'health#show'
      get :sla_dashboard, to: 'sla_dashboard#show'
      get 'admin/tickets', to: 'admin_tickets#index'

      resource :session, only: %i[create destroy]
      resource :me, only: %i[show update destroy], controller: 'me' do
        get :export
      end
      resources :users, only: %i[index create update]
      resources :tags, only: %i[index]
      resources :tickets, only: %i[index show create update destroy] do
        collection do
          get :search
        end
        resources :comments, only: %i[index create destroy]
        resources :attachments, only: %i[index create destroy]
        resources :tags, only: %i[index create destroy], controller: 'ticket_tags'
      end
    end
  end
end
