FactoryBot.define do
  factory :users_totp_credential, class: "User::TotpCredential" do
    user
    otp_secret { ROTP::Base32.random }
    otp_enabled { false }

    trait :enabled do
      otp_enabled { true }
    end
  end
end
