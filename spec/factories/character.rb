FactoryBot.define do
  factory :character do
    association :user, factory: user

    lodestone_id { 12345678 }
    character_name { 'G\'raha Tia' }
    home_world { 'Balmung' }
  end

  factory :random_character, class: Character do
    association :user, factory: :random_user

    lodestone_id { Faker::Number.unique.number(digits: 8) }
    character_name { Faker::Games::Touhou.character }
    home_datacenter { Faker::Books::Dune.planet }
    home_world { Faker::Games::DnD.city }
    avatar_url { "https://picsum.photos/seed/#{lodestone_id}/96/96" }
  end
end
