require_relative "../support/pki_support"

FactoryBot.define do
  factory :pki_issued_certificate, class: "PKI::IssuedCertificate" do
    # Generates a certificate *without* using shared keys, as that may muck up tests where we need multiple certs.
    # Speed-wise, this shouldn't be a problem as we use EC curves.

    transient do
      cert_uuid { SecureRandom.uuid_v7 }
    end

    id { cert_uuid }
    certificate_authority { association :pki_certificate_authority }
    subject { association :user }
    certificate_pem do
      serial = cert_uuid.delete("-").to_i(16)
      PkiSupport.generate_leaf_pem(
        certificate_authority.as_openssl_certificate, certificate_authority.as_openssl_pkey,
        cn: "user:#{subject&.id || 'test'}", serial: serial
      )
    end
    issued_at { Time.current }
    expires_at { 1.year.from_now }
    public_key_info { { "type" => "EC", "curve" => "prime256v1", "bits" => 256 } }
    certificate_fingerprint { "sha256:#{SecureRandom.hex(32)}" }
    public_key_fingerprint { "sha256:#{SecureRandom.hex(32)}" }

    trait :for_character_registration do
      subject { association :verified_registration }
    end

    trait :revoked do
      revoked_at { 1.day.ago }
      revocation_reason { "unspecified" }
    end

    trait :expired do
      issued_at { 2.years.ago }
      expires_at { 1.year.ago }
    end

    trait :renewable do
      issued_at { 10.months.ago }
      expires_at { 2.months.from_now }
    end
  end
end
