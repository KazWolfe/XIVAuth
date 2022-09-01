require 'sidekiq/web'

Rails.application.routes.draw do
  use_doorkeeper
  devise_for :users

  scope :module => "portal" do
    # User management
    get "/profile", to: "profile#index"
    post "/profile", to: "profile#update"

    # Character management
    resources :characters
    get "/characters/:id/verify", to: 'characters#verify'
    post "/characters/:id/verify", to: 'characters#enqueue_verify'
  end

  namespace :admin do
    resources :users
    resources :characters
  end

  # Defines the root path route ("/")
  root 'marketing#index'

  # Other interfaces
  mount Sidekiq::Web => '/admin/sidekiq'
end
