require "rails_helper"

RSpec.describe JwtSigningKey, type: :model do
  describe "lifecycle and flags" do
    it "computes expired? correctly" do
      key = JwtSigningKeys::HMAC.create!(name: "exp_test_#{SecureRandom.uuid}")
      expect(key).not_to be_expired

      key.update!(expires_at: 10.minutes.from_now)
      expect(key).not_to be_expired

      key.update!(expires_at: 1.minute.ago)
      expect(key).to be_expired
    end

    it "computes active? correctly from enabled and expired" do
      key = JwtSigningKeys::HMAC.create!(name: "active_test_#{SecureRandom.uuid}")
      expect(key).to be_active

      key.update!(enabled: false)
      expect(key).not_to be_active

      key.update!(enabled: true, expires_at: 1.minute.ago)
      expect(key).not_to be_active
    end

    it "filters only active keys in .active scope" do
      active_rsa = JwtSigningKeys::RSA.create!(name: "rsa_#{SecureRandom.uuid}")
      _inactive = JwtSigningKeys::HMAC.create!(name: "hmac_#{SecureRandom.uuid}", enabled: false)
      _expired = JwtSigningKeys::RSA.create!(name: "rsa_exp_#{SecureRandom.uuid}", expires_at: 1.hour.ago)

      expect(JwtSigningKey.active).to contain_exactly(active_rsa)
    end

    it "returns name in to_param" do
      key = JwtSigningKeys::HMAC.create!(name: "param_#{SecureRandom.uuid}")
      expect(key.to_param).to eq(key.name)
    end
  end

  describe "JWKS and JWK export" do
    it "includes only active keys in JWKS with correct kids" do
      rsa_active = JwtSigningKeys::RSA.create!(name: "rsa_jwks_#{SecureRandom.uuid}")
      hmac_active = JwtSigningKeys::HMAC.create!(name: "hmac_jwks_#{SecureRandom.uuid}")
      _expired = JwtSigningKeys::HMAC.create!(name: "hmac_jwks_exp_#{SecureRandom.uuid}", expires_at: 1.hour.ago)

      set = JwtSigningKey.jwks
      expect(set).to be_a(JWT::JWK::Set)
      kids = set.export[:keys].map { |k| k[:kid] }

      expect(kids).to include(rsa_active.name, hmac_active.name)
      expect(kids).not_to include(_expired.name)
    end

    it "exports algs and exp fields on JWK when present" do
      rsa = JwtSigningKeys::RSA.create!(name: "rsa_export_#{SecureRandom.uuid}")
      rsa.update!(expires_at: 2.hours.from_now)

      jwk = rsa.jwk
      exported = jwk.export

      expect(exported[:kid]).to eq(rsa.name)
      expect(exported[:use]).to eq("sig")
      expect(exported[:algs]).to include(*rsa.supported_algorithms)
      expect(exported[:exp]).to be_within(5).of(rsa.expires_at.to_i)
    end
  end

  describe ".preferred_key_for_algorithm" do
    before(:context) do
      @rsa_key = JwtSigningKeys::RSA.create!(name: "rsa_pref_#{SecureRandom.uuid}")
      @hmac_key = JwtSigningKeys::HMAC.create!(name: "hmac_pref_#{SecureRandom.uuid}")
      @eddsa_key = JwtSigningKeys::Ed25519.create!(name: "eddsa_pref_#{SecureRandom.uuid}")
      @ecdsa_key = JwtSigningKeys::ECDSA.create!(name: "ecdsa_pref_#{SecureRandom.uuid}", curve: "prime256v1")
    end

    it "returns RSA for RS256 and PS256 families" do
      expect(JwtSigningKey.preferred_key_for_algorithm("RS256")).to eq(@rsa_key)
      expect(JwtSigningKey.preferred_key_for_algorithm("PS256")).to eq(@rsa_key)
    end

    it "returns HMAC for HS256 family" do
      expect(JwtSigningKey.preferred_key_for_algorithm("HS256")).to eq(@hmac_key)
    end

    it "returns Ed25519 for EdDSA" do
      expect(JwtSigningKey.preferred_key_for_algorithm("EdDSA")).to eq(@eddsa_key)
    end

    it "returns a matching ECDSA key for ECDSA curves" do
      expect(JwtSigningKey.preferred_key_for_algorithm("ES256")).to eq(@ecdsa_key)
    end

    it "returns nil for unknown algorithm" do
      expect(JwtSigningKey.preferred_key_for_algorithm("foo.bar")).to be_nil
    end
  end
end
