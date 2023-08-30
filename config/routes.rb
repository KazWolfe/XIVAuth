require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  root 'marketing#index'

  resources :characters, controller: :character_registrations, as: :character_registrations, except: [:update] do
    resource :verify, controller: 'character_registrations/verifications'

    post 'refresh', to: 'character_registrations#refresh'
  end

  namespace 'developer' do
    resources :applications, controller: 'client_apps' do
      post 'regenerate_secret', to: 'client_apps#regenerate', on: :member
    end
  end

  namespace 'api' do
    namespace 'v1' do
      resource :user, only: %i[show update] do
        get 'jwt', to: 'users#jwt'
      end

      resources :characters, param: :lodestone_id do
        post 'verify', to: 'characters#verify'
        delete 'verify', to: 'characters#unverify'
        get 'jwt', to: 'characters#jwt', on: :member
      end

      post 'jwt/verify', to: 'jwt#verify'
      get 'jwt/jwks', to: 'jwt#jwks'
      get 'jwt/gen_jwt', to: 'jwt#dummy_jwt'
    end
  end

  # Admin routes
  authenticate :user, ->(u) { u.admin? } do
    namespace 'admin' do
      root to: 'dashboard#index'

      resources :users, controller: 'users'
      resources :characters, controller: 'characters', param: :lodestone_id do
        post :refresh, on: :member
        resource :ban, controller: 'character/character_bans'
      end

      resources :client_applications, controller: 'client_applications'

      mount Sidekiq::Web => '/sidekiq'
      mount Flipper::UI.app(Flipper) => '/flipper'
    end
  end

  scope path: '/legal', as: :legal, controller: :legal do
    get 'terms', to: 'legal#terms_of_service'
    get 'privacy', to: 'legal#privacy_policy'
    get 'devagreement', to: 'legal#developer_agreement'
    get 'security', to: 'legal#security_policy'
  end

  resource :health, only: [:show], controller: :health

  use_doorkeeper do
    controllers authorizations: 'oauth/authorizations'
  end
  use_doorkeeper_device_authorization_grant do; end

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
    resources :webauthn_credentials, path: '/profile/webauthn', controller: 'users/webauthn_credentials', only: %i[new create destroy]
    resource :totp_credential, path: '/profile/totp', controller: 'users/totp_credentials', only: %i[new create destroy]
  end
end
