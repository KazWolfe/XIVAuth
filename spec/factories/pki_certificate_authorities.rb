require_relative "../support/pki_support"

FactoryBot.define do
  factory :pki_certificate_authority, class: "PKI::CertificateAuthority" do
    sequence(:slug) { |n| "test-ca-#{n}" }
    certificate_pem { PkiSupport.generate_ca_cert(key: PkiSupport.shared_ecdsa_key) }
    private_key     { PkiSupport.shared_ecdsa_key.to_pem }
    active          { true }
    allowed_certificate_types { %w[user_identification character_identification code_signing] }

    trait :inactive do
      active { false }
    end

    trait :revoked do
      revoked_at        { 1.day.ago }
      revocation_reason { "key_compromise" }
      active            { false }
    end

    trait :user_identification_only do
      allowed_certificate_types { %w[user_identification] }
    end

    trait :character_identification_only do
      allowed_certificate_types { %w[character_identification] }
    end

    trait :code_signing_only do
      allowed_certificate_types { %w[code_signing] }
    end
  end
end
