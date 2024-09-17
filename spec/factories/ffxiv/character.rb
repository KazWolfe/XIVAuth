FactoryBot.define do
  factory :ffxiv_character, class: "FFXIV::Character" do
    lodestone_id { Faker::Number.unique.number(digits: 8) }
    name { Faker::Games::Touhou.character }
    home_world { Faker::Games::DnD.city }
    data_center { Faker::Books::Dune.planet }
    avatar_url { "https://picsum.photos/seed/#{lodestone_id}/96/96" }
    portrait_url { "https://picsum.photos/seed/#{lodestone_id}/640/873" }
  end
end
