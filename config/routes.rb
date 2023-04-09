Rails.application.routes.draw do
  root 'marketing#index'

  resources :characters, controller: :character_registrations, as: :character_registrations,
            only: %i[index show new create destroy] do
    get 'verify', to: 'character_registration_verification#index'
    post 'verify', to: 'character_registration_verification#create'
    delete 'verify', to: 'character_registration_verification#destroy'
  end

  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    omniauth_callbacks: 'users/omniauth_callbacks',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks'
  }
end
