FactoryBot.define do
  factory :client_application do
    name { "App #{SecureRandom.uuid}" }

    # 'private' collides with Ruby keyword; use add_attribute to set it
    add_attribute(:private) { false }
    owner { nil }

    after(:build) do |app|
      app.build_profile unless app.profile
    end
  end
end
