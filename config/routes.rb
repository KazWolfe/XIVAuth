require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  use_doorkeeper_openid_connect

  use_doorkeeper do
    controllers authorizations: 'oauth/authorizations',
                tokens: 'oauth/tokens'
  end

  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  scope module: :portal do
    # User management
    get '/profile', to: 'profile#show'
    post '/profile', to: 'profile#update'
    put '/profile', to: 'profile#update'
    patch '/profile', to: 'profile#update'
    delete '/profile/social_identity/:id', to: 'profile#destroy_social_identity'
    get '/profile/password', to: 'profile#password_modal'
    patch '/profile/password', to: 'profile#update_password'

    # Character management
    resources :characters, except: [:show] do
      get 'verify', on: :member
      post 'verify', on: :member, to: 'characters#enqueue_verify'
    end

    # Developer
    namespace :developer do
      resources :applications, controller: 'client_applications'
    end
  end

  # Admin routes
  authenticate :user, ->(u) { u.admin? } do
    namespace :admin do
      resources :users
      resources :characters
      resources :applications, controller: 'client_applications'
    end

    mount Sidekiq::Web => '/admin/sidekiq'
  end

  namespace :api do
    resources :characters
    resources :user
  end

  # Defines the root path route ("/")
  root 'marketing#index'
end
