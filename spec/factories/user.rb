FactoryBot.define do
  factory :user do
    email { Faker::Internet.email(domain: "example.test") }
    password { Faker::Internet.password }
    confirmed_at { DateTime.now }

    profile { association :users_profile, user: instance }
  end
end
