FactoryBot.define do
  factory :team do
    association :owner, factory: user

    name { "My Awesome Team" }
  end

  factory :random_team, class: Team do
    association :owner, factory: :random_user

    name { Faker::Team.name }
  end
end
