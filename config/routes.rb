require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  root "marketing#index"

  resources :characters, controller: :character_registrations, as: :character_registrations, except: [:update] do
    resource :verify, controller: "character_registrations/verifications"

    post "refresh", to: "character_registrations#refresh"
  end

  namespace "developer" do
    resources :applications, controller: "client_apps" do
      resources :oauth_clients, controller: "client_apps/oauth_clients", shallow: true do
        post "regenerate_secret", to: "client_apps/oauth_clients#regenerate", on: :member
      end
    end

    resources :teams, controller: "teams" do
      resources :invite_links, controller: "teams/invite_links", shallow: true, param: :code,
                shallow_path: "teams", shallow_prefix: "team"

      get "join/:code", to: "teams#accept_invite", on: :collection, as: :accept_invite
    end
  end

  namespace "api" do
    namespace "v1" do
      resource :user, only: %i[show update] do
        get "jwt", to: "users#jwt"
      end

      resources :characters, param: :lodestone_id do
        post "verify", to: "characters#verify"
        delete "verify", to: "characters#unverify"
        get "jwt", to: "characters#jwt", on: :member
      end

      post "jwt/verify", to: "jwt#verify"
      get "jwt/jwks", to: "jwt#jwks"
      get "jwt/gen_jwt", to: "jwt#dummy_jwt"
    end
  end

  # Admin routes
  authenticate :user, ->(u) { u.admin? } do
    namespace "admin" do
      root to: "dashboard#index"

      resources :users, controller: "users" do
        delete :mfa, on: :member, to: "users#destroy_mfa"
        post :reset_password, on: :member, to: "users#send_password_reset"
        post :confirm, on: :member, to: "users#confirm"
      end
      resources :characters, controller: "characters", param: :lodestone_id do
        post :refresh, on: :member
        resource :ban, controller: "character/character_bans"
      end

      resources :character_registrations, controller: "character_registrations" do
        post :verify, on: :member
        delete :verify, on: :member, to: "character_registrations#unverify"
      end

      resources :client_applications, controller: "client_applications"
      resources :jwt_keys, controller: "jwt_keys", only: %i[index show], param: :name

      mount Sidekiq::Web => "/sidekiq"
      mount Flipper::UI.app(Flipper) => "/flipper"
    end
  end

  scope path: "/legal", as: :legal, controller: :legal do
    get "terms", to: "legal#terms_of_service"
    get "privacy", to: "legal#privacy_policy"
    get "devagreement", to: "legal#developer_agreement"
    get "security", to: "legal#security_policy"
  end

  resource :health, only: [:show], controller: :health

  if Rails.env.development? || ENV["APP_ENV"].present? && ENV["APP_ENV"] != "production"
    get "/_debug/generate_exception", to: "debug#generate_exception"
  end

  use_doorkeeper do
    controllers authorizations: "oauth/authorizations"
  end
  use_doorkeeper_device_authorization_grant {}

  devise_for :users, path: "auth", only: [:omniauth_callbacks],
             controllers: {
               omniauth_callbacks: "users/omniauth_callbacks",
             }

  devise_scope :user do
    scope :auth do
      get "login", to: "users/sessions#new", as: :new_user_session
      post "login", to: "users/sessions#create", as: :user_session
      delete "logout", to: "users/sessions#destroy", as: :destroy_user_session

      get "register", to: "users/registrations#new", as: :new_user_registration
      post "register", to: "users/registrations#create", as: :user_registration
      get "register/post_signup", to: "users/registrations#post_signup", as: :user_post_registration
      get "register/confirm", to: "users/confirmations#show", as: :user_confirmation

      get "recovery", to: "users/recovery#new", as: :begin_user_recovery
      post "recovery", to: "users/recovery#create", as: :user_recovery

      get "recovery/password", to: "users/passwords#edit", as: :reset_user_password
      put "recovery/password", to: "users/passwords#update"
    end

    scope "users" do
      # TODO: Remove eventually. Deprecated routes that might still be active via emails.

      get "password/edit", to: "users/passwords#edit"
      get "confirmation", to: "users/confirmations#show"
    end

    resource :profile, as: "user", only: %i[update destroy], controller: "users/registrations" do
      get "/", to: "users/registrations#edit", as: :edit

      resources :social_identities, path: "identities", controller: "users/social_identities", only: [:destroy]
      resources :webauthn_credentials, path: "webauthn", controller: "users/webauthn_credentials",
                only: %i[new create destroy]
      resource :totp_credential, path: "totp", controller: "users/totp_credentials", only: %i[new create destroy]
    end
  end
end
