FactoryBot.define do
  factory :user do

  end

  factory :random_user, class: User do
    transient {
      fake_iuser { Faker::Internet.user('username', 'safe_email', 'password') }
    }

    username { fake_iuser[:username] }
    email { fake_iuser[:safe_email] }
    password { fake_iuser[:password] }
  end
end
