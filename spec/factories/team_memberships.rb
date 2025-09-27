FactoryBot.define do
  factory :team_membership, class: "Team::Membership" do
    association :team
    association :user
    role { "member" }

    trait :admin do
      role { "admin" }
    end

    trait :developer do
      role { "developer" }
    end
  end
end

