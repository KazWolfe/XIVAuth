FactoryBot.define do
  factory :team_membership do
    association :user, factory: user
    association :team, factory: team

    role { :admin }
  end

  factory :random_team_membership, class: TeamMembership do
    association :user, factory: :random_user
    association :team, factory: :random_team

    role { [:admin, :developer, :user].sample }
  end
end
