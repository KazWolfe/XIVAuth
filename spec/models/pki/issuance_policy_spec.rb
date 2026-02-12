require "rails_helper"

RSpec.describe PKI::IssuancePolicy, type: :model do
  let(:ca)      { FactoryBot.create(:pki_certificate_authority) }
  let(:user)    { FactoryBot.create(:user) }
  let(:ec_key)  { OpenSSL::PKey::EC.generate("prime256v1") }
  let(:rsa_key) { PkiSupport.shared_rsa_key }

  # Default policy uses EC - fast for the bulk of tests.
  def build_policy(subject: user, public_key: ec_key, ca: self.ca, requesting_application: nil)
    PKI::IssuancePolicy.for(
      subject: subject, public_key: public_key,
      certificate_authority: ca, requesting_application: requesting_application
    )
  end

  describe ".for factory" do
    it "returns UserPolicy for User subjects" do
      expect(build_policy).to be_a(PKI::IssuancePolicy::UserPolicy)
    end

    it "returns CharacterRegistrationPolicy for CharacterRegistration subjects" do
      cr = FactoryBot.create(:verified_registration)
      policy = PKI::IssuancePolicy.for(subject: cr, public_key: ec_key, certificate_authority: ca)
      expect(policy).to be_a(PKI::IssuancePolicy::CharacterRegistrationPolicy)
    end

    it "raises for unknown subject types" do
      expect {
        PKI::IssuancePolicy.for(subject: Object.new, public_key: ec_key, certificate_authority: ca)
      }.to raise_error(ArgumentError, /No PKI issuance policy/)
    end
  end

  describe "key type validation" do
    it "is valid for EC keys on an allowed curve (default)" do
      expect(build_policy).to be_valid
    end

    it "is valid for RSA keys" do
      expect(build_policy(public_key: rsa_key)).to be_valid
    end
  end

  describe "key strength validation" do
    it "rejects RSA keys below 2048 bits" do
      small_key = OpenSSL::PKey::RSA.new(1024)
      policy = build_policy(public_key: small_key)

      expect(policy).not_to be_valid
      expect(policy.errors[:public_key]).to include(match(/RSA key too small/))
    end

    it "rejects EC keys on disallowed curves" do
      weak_ec = OpenSSL::PKey::EC.generate("secp112r1") rescue nil
      skip "secp112r1 not available" unless weak_ec

      policy = build_policy(public_key: weak_ec)
      expect(policy).not_to be_valid
      expect(policy.errors[:public_key]).to include(match(/EC curve not allowed/))
    end
  end

  describe "CA validation" do
    it "rejects inactive CA" do
      inactive_ca = FactoryBot.create(:pki_certificate_authority, :inactive)
      expect(build_policy(ca: inactive_ca)).not_to be_valid
    end

    it "rejects revoked CA" do
      revoked_ca = FactoryBot.create(:pki_certificate_authority, :revoked)
      expect(build_policy(ca: revoked_ca)).not_to be_valid
    end

    it "rejects CA not permitted for the subject type" do
      users_only_ca = FactoryBot.create(:pki_certificate_authority, :users_only)
      cr = FactoryBot.create(:verified_registration)
      policy = PKI::IssuancePolicy.for(subject: cr, public_key: ec_key, certificate_authority: users_only_ca)

      expect(policy).not_to be_valid
      expect(policy.errors[:certificate_authority]).to be_present
    end
  end

  describe "certificate limit validation" do
    it "rejects issuance when limit is reached" do
      FactoryBot.create_list(:pki_issued_certificate, 2, subject: user, certificate_authority: ca,
                  requesting_application_id: nil)

      expect(build_policy).not_to be_valid
    end

    it "counts limits separately per requesting application" do
      app1 = FactoryBot.create(:client_application)
      app2 = FactoryBot.create(:client_application)
      FactoryBot.create_list(:pki_issued_certificate, 2, subject: user, certificate_authority: ca,
                  requesting_application: app1)

      policy = PKI::IssuancePolicy.for(subject: user, public_key: ec_key,
                                       certificate_authority: ca, requesting_application: app2)
      expect(policy).to be_valid
    end
  end

  describe "keyUsage and EKU for UserPolicy" do
    it "uses digitalSignature only (no keyAgreement or keyEncipherment)" do
      usage = build_policy(public_key: ec_key).signing_profile["extensions"]["keyUsage"]["usage"]
      expect(usage).to eq(%w[digitalSignature])
    end

    it "uses digitalSignature only for RSA keys too" do
      usage = build_policy(public_key: rsa_key).signing_profile["extensions"]["keyUsage"]["usage"]
      expect(usage).to eq(%w[digitalSignature])
    end

    it "uses clientAuth EKU" do
      eku = build_policy.signing_profile["extensions"]["extendedKeyUsage"]["usage"]
      expect(eku).to eq(%w[clientAuth])
    end
  end

  describe "keyUsage and EKU for CharacterRegistrationPolicy" do
    let(:cr) { FactoryBot.create(:verified_registration) }

    def build_cr_policy(public_key: ec_key)
      PKI::IssuancePolicy.for(subject: cr, public_key: public_key, certificate_authority: ca)
    end

    it "includes digitalSignature and keyAgreement for EC" do
      usage = build_cr_policy(public_key: ec_key).signing_profile["extensions"]["keyUsage"]["usage"]
      expect(usage).to include("digitalSignature", "keyAgreement")
      expect(usage).not_to include("keyEncipherment")
    end

    it "includes digitalSignature and keyEncipherment for RSA" do
      usage = build_cr_policy(public_key: rsa_key).signing_profile["extensions"]["keyUsage"]["usage"]
      expect(usage).to include("digitalSignature", "keyEncipherment")
      expect(usage).not_to include("keyAgreement")
    end

    it "uses emailProtection EKU" do
      eku = build_cr_policy.signing_profile["extensions"]["extendedKeyUsage"]["usage"]
      expect(eku).to eq(%w[emailProtection])
    end
  end

  describe "revoked key validation" do
    let(:revoked_key)         { OpenSSL::PKey::EC.generate("prime256v1") }
    let(:revoked_fingerprint) { "sha256:#{OpenSSL::Digest::SHA256.hexdigest(revoked_key.to_der)}" }

    it "rejects a key that was used in a revoked certificate" do
      FactoryBot.create(:pki_issued_certificate, :revoked, subject: user, certificate_authority: ca,
                        public_key_fingerprint: revoked_fingerprint)
      policy = build_policy(public_key: revoked_key)

      expect(policy).not_to be_valid
      expect(policy.errors[:public_key]).to include(match(/has been revoked/))
    end

    it "allows a fresh key even when the same subject has a revoked cert under a different key" do
      FactoryBot.create(:pki_issued_certificate, :revoked, subject: user, certificate_authority: ca)
      expect(build_policy(public_key: OpenSSL::PKey::EC.generate("prime256v1"))).to be_valid
    end

  end

  describe "key subject uniqueness validation" do
    # Each test here needs a cert with a known fingerprint plus a policy using the same
    # key, so we generate a fresh EC key rather than the shared outer let.
    let(:fresh_key)         { OpenSSL::PKey::EC.generate("prime256v1") }
    let(:fresh_fingerprint) { "sha256:#{OpenSSL::Digest::SHA256.hexdigest(fresh_key.to_der)}" }

    it "allows the same key to be reused for the same subject when in the renewal window" do
      FactoryBot.create(:pki_issued_certificate, :renewable, subject: user, certificate_authority: ca,
                        public_key_fingerprint: fresh_fingerprint)
      policy = build_policy(subject: user, public_key: fresh_key)

      expect(policy).to be_valid
    end

    it "rejects a key already used for a different user" do
      other_user = FactoryBot.create(:user)
      FactoryBot.create(:pki_issued_certificate, subject: other_user, certificate_authority: ca,
                        public_key_fingerprint: fresh_fingerprint)
      policy = build_policy(subject: user, public_key: fresh_key)

      expect(policy).not_to be_valid
      expect(policy.errors[:public_key]).to include(match(/already associated with a different subject/))
    end

    it "rejects a key already used for a different subject type (user → character)" do
      FactoryBot.create(:pki_issued_certificate, subject: user, certificate_authority: ca,
                        public_key_fingerprint: fresh_fingerprint)
      cr     = FactoryBot.create(:verified_registration)
      policy = PKI::IssuancePolicy.for(subject: cr, public_key: fresh_key, certificate_authority: ca)

      expect(policy).not_to be_valid
      expect(policy.errors[:public_key]).to include(match(/already associated with a different subject/))
    end

    it "allows a fresh key even when the subject already has certs under a different key" do
      FactoryBot.create(:pki_issued_certificate, subject: user, certificate_authority: ca)
      policy = build_policy(subject: user, public_key: ec_key)

      expect(policy).to be_valid
    end
  end

  describe "renewal window validation" do
    let(:renewal_key)         { OpenSSL::PKey::EC.generate("prime256v1") }
    let(:renewal_fingerprint) { "sha256:#{OpenSSL::Digest::SHA256.hexdigest(renewal_key.to_der)}" }

    it "allows first issuance with a fresh key regardless of timing" do
      expect(build_policy(public_key: renewal_key)).to be_valid
    end

    it "allows renewal when 75% of a 1-year cert's life has elapsed" do
      FactoryBot.create(:pki_issued_certificate, :renewable, subject: user, certificate_authority: ca,
                        public_key_fingerprint: renewal_fingerprint)
      expect(build_policy(public_key: renewal_key)).to be_valid
    end

    it "allows renewal when over 1 year has passed on a long-lived cert" do
      FactoryBot.create(:pki_issued_certificate, subject: user, certificate_authority: ca,
                        public_key_fingerprint: renewal_fingerprint,
                        issued_at: 13.months.ago, expires_at: 11.months.from_now)
      expect(build_policy(public_key: renewal_key)).to be_valid
    end

    it "blocks renewal when less than 75% of a 1-year cert's life has elapsed" do
      FactoryBot.create(:pki_issued_certificate, subject: user, certificate_authority: ca,
                        public_key_fingerprint: renewal_fingerprint,
                        issued_at: 3.months.ago, expires_at: 9.months.from_now)
      policy = build_policy(public_key: renewal_key)

      expect(policy).not_to be_valid
      expect(policy.errors[:base]).to include(match(/not yet eligible for renewal/))
    end

    it "does not apply the renewal window when using a new key" do
      # Existing cert under a different key should not trigger renewal window
      FactoryBot.create(:pki_issued_certificate, subject: user, certificate_authority: ca,
                        issued_at: 1.day.ago, expires_at: 1.year.from_now)
      expect(build_policy(public_key: renewal_key)).to be_valid
    end
  end

  describe "CharacterRegistrationPolicy" do
    let(:cr)          { FactoryBot.create(:verified_registration) }
    let(:cr_key)      { OpenSSL::PKey::EC.generate("prime256v1") }
    let(:cr_key_fp)   { "sha256:#{OpenSSL::Digest::SHA256.hexdigest(cr_key.to_der)}" }

    def build_cr_policy(subject: cr, public_key: cr_key)
      PKI::IssuancePolicy.for(subject: subject, public_key: public_key, certificate_authority: ca)
    end

    it "rejects unverified CharacterRegistration" do
      unverified = FactoryBot.create(:character_registration)
      policy = PKI::IssuancePolicy.for(subject: unverified, public_key: ec_key, certificate_authority: ca)

      expect(policy).not_to be_valid
      expect(policy.errors[:subject]).to include(match(/must be verified/))
    end
  end
end
