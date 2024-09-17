FactoryBot.define do
  factory :oauth_client_application, class: "OAuth::ClientApplication" do
    name { Faker::App.name }
    uid { SecureRandom.uuid }
    secret { SecureRandom.uuid }
    redirect_uri { Faker::Internet.url(scheme: "https") }
    confidential { true }
  end
end
