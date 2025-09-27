FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    inherit_parent_memberships { true }

    trait :no_inherit do
      inherit_parent_memberships { false }
    end

    trait :with_parent do
      association :parent, factory: :team
    end
  end
end
