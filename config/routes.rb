require 'sidekiq/web'

Rails.application.routes.draw do
  use_doorkeeper_openid_connect

  use_doorkeeper do
    controllers authorizations: 'oauth/authorizations',
                tokens: 'oauth/tokens'
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  scope :module => "portal" do
    # User management
    get "/profile", to: "profile#index"
    post "/profile", to: "profile#update"
    put "/profile", to: "profile#update"
    patch "/profile", to: "profile#update"

    # Character management
    resources :characters do
      get 'verify', on: :member
      post 'verify', on: :member
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
