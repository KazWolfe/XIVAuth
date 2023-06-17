FactoryBot.define do
  factory :user do
    email { Faker::Internet.email(domain: 'example.test') }
    password { Faker::Internet.password }
    confirmed_at { DateTime.now }
  end
end
