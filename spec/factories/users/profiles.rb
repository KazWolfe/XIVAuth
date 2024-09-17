FactoryBot.define do
  factory :users_profile, class: "Users::Profile" do
    user
    display_name { "TEST_#{Faker::Internet.username(specifier: 6..24)}" }
  end
end
