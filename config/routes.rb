require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root 'marketing#index'

  resources :characters, controller: :character_registrations, as: :character_registrations, except: [:update] do
    resource :verify, controller: 'character_registration_verifications'

    post 'refresh', to: 'character_registrations#refresh'
  end

  namespace 'developer' do
    resources :applications, controller: 'client_apps'
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
    namespace 'admin' do
      root to: 'dashboard#index'

      mount Sidekiq::Web => '/sidekiq'
      mount Flipper::UI.app(Flipper) => '/flipper'
    end
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
    resource :totp_credential, path: '/profile/totp', controller: 'users/totp_credentials', only: [:new, :create, :destroy]
  end
end
