require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root 'marketing#index'

  resources :characters, controller: :character_registrations, as: :character_registrations, except: [:update] do
    get 'verify', to: 'character_registration_verification#index'
    post 'verify', to: 'character_registration_verification#create'
    delete 'verify', to: 'character_registration_verification#destroy'

    post 'refresh', to: 'character_registrations#refresh'
  end

  namespace 'developer' do
    resources :applications, controller: 'oauth_apps'
  end

  namespace 'api' do
    namespace 'v1' do
      resources :user
      resources :characters, param: :lodestone_id do
        post 'verify', to: 'characters#verify'
        delete 'verify', to: 'characters#unverify'
      end
    end
  end

  # Admin routes
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

  use_doorkeeper do; end

  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks'
  }

  devise_scope :user do
    resources :social_identities, path: '/profile/identities', controller: 'users/social_identities', only: [:destroy]
    resources :webauthn_credentials, path: '/profile/webauthn', controller: 'users/webauthn_credentials', only: [:new, :create, :destroy]
  end
end
