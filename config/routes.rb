require 'sidekiq/web'

Rails.application.routes.draw do
  use_doorkeeper_openid_connect
  use_doorkeeper
  devise_for :users

  scope :module => "portal" do
    # User management
    get "/profile", to: "profile#index"
    post "/profile", to: "profile#update"
    put "/profile", to: "profile#update"
    patch "/profile", to: "profile#update"

    # Character management
    resources :characters
    get "/characters/:id/verify", to: 'characters#verify'
    post "/characters/:id/verify", to: 'characters#enqueue_verify'
    
    # Developer
    namespace :developer do
      resources :client_applications
    end
  end

  namespace :admin do
    resources :users
    resources :characters
  end

  namespace :api do
    resources :characters
    resources :user
  end

  # Defines the root path route ("/")
  root 'marketing#index'

  # Other interfaces
  mount Sidekiq::Web => '/admin/sidekiq'
end
