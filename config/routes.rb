# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq' if Rails.env.development? || ENV['SIDEKIQ_WEB_USERNAME'].present?

  namespace :api do
    namespace :v1 do
      get :health, to: 'health#show'
      post :notification_test, to: 'notification_tests#create'
      get :sla_dashboard, to: 'sla_dashboard#show'
      get :sla_analytics, to: 'sla_analytics#show'
      get 'admin/tickets', to: 'admin_tickets#index'

      resource :session, only: %i[create destroy]
      resource :me, only: %i[show update destroy], controller: 'me'
      resources :users, only: %i[index create update] do
        collection do
          get :search
        end
      end
      resources :tags, only: %i[index]
      resources :tickets, only: %i[index show create update destroy] do
        collection do
          get :search
        end
        resource :sla_notify, only: %i[create], controller: 'ticket_sla_notifications'
        resources :comments, only: %i[index create destroy]
        resources :attachments, only: %i[index create destroy]
        resources :tags, only: %i[index create destroy], controller: 'ticket_tags'
      end
    end
  end
end
