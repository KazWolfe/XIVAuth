require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  use_doorkeeper_openid_connect

  use_doorkeeper do
    skip_controllers :applications
    controllers authorizations: 'oauth/authorizations',
                tokens: 'oauth/tokens'
  end

  use_doorkeeper_device_authorization_grant do
    skip_controllers :device_authorizations
    controller device_codes: 'oauth/device_codes'
  end

  namespace :oauth do
    resources :device, controller: 'device_authorizations', only: [:index, :create, :show, :destroy], param: :user_code do
      post '/', on: :member, to: 'device_authorizations#update'
    end
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
    resource :profile, only: [:index, :show, :update] do
      scope module: :profile do
        resources :external_identities, only: [:destroy]
        resources :webauthn_credentials, only: [:create, :destroy] do
          post '/challenge', on: :collection, action: 'webauthn_credentials#challenge'
        end
      end

      get '/password', to: 'profile#password_modal'
      patch '/password', to: 'profile#update_password'
    end

    # Character management
    resources :characters do
      get 'verify', on: :member
      post 'verify', on: :member, to: 'characters#enqueue_verify'
    end

    # Developer
    namespace :developer do
      resources :applications, controller: 'client_applications'
    end
  end

  resolve("Profile") { [:profile] }

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
