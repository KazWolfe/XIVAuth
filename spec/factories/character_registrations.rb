FactoryBot.define do
  factory :character_registration do
    user { association :user }
    character { association :ffxiv_character }

    factory :verified_registration do
      verified_at { DateTime.now }
      verification_type { "test_suite" }
    end
  end
end
