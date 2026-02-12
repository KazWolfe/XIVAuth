require_relative "../support/pki_support"

FactoryBot.define do
  factory :jwt_signing_key do
    factory :jwt_signing_keys_hmac, class: "JwtSigningKeys::HMAC" do
      sequence(:name) { |n| "hmac_key_#{n}" }
      enabled { true }
    end

    factory :jwt_signing_keys_ed25519, class: "JwtSigningKeys::Ed25519" do
      sequence(:name) { |n| "ed25519_key_#{n}" }
      enabled { true }
      private_key { PkiSupport.shared_ed25519_key }
    end

    factory :jwt_signing_keys_rsa, class: "JwtSigningKeys::RSA" do
      sequence(:name) { |n| "rsa_key_#{n}" }
      enabled { true }
      private_key { PkiSupport.shared_rsa_key }
    end

    factory :jwt_signing_keys_ecdsa, class: "JwtSigningKeys::ECDSA" do
      sequence(:name) { |n| "ecdsa_key_#{n}" }
      enabled { true }
      private_key { PkiSupport.shared_ecdsa_key("prime256v1") }
    end
  end
end
