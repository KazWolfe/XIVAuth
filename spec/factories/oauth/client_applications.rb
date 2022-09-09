FactoryBot.define do
  factory :oauth_client_application, class: 'Oauth::ClientApplication' do
    association :owner, factory: :user

    name { 'My Sample Application' }
    redirect_uri { 'http://example.invalid/oauth/redirect' }
    scopes { 'character user' }
  end

  factory :random_oauth_client_application, class: 'Oauth::ClientApplication' do
    association :owner, factory: :random_user

    name { Faker::App.name }
    redirect_uri { "https://#{Faker::Internet.domain_word}.invalid/oauth/authenticate" }
    scopes { 'character user' }
  end
end
