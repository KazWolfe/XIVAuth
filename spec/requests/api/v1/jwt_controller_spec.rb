require "rails_helper"
require "support/oauth_contexts"

RSpec.describe "Api::V1::JwtController", type: :request do
  include_context "oauth:client_credentials"

  # Key generation is expensive, do it once.
  before(:all) do
    @test_key = JwtSigningKeys::HMAC.create!(name: "hmac_spec_#{SecureRandom.uuid}")
    @rsa_key =  JwtSigningKeys::RSA.create!(name: "rsa_spec_#{SecureRandom.uuid}", size: 1024)
    @ed25519_key = JwtSigningKeys::Ed25519.create!(name: "ed25519_spec_#{SecureRandom.uuid}")
    @ecdsa_key = JwtSigningKeys::ECDSA.create!(name: "ecdsa_spec_#{SecureRandom.uuid}")
  end

  describe "GET /api/v1/jwt/jwks" do
    it "does not require authentication" do
      get api_v1_jwt_jwks_path  # no auth header
      expect(response).to be_successful
    end

    it "returns only active keys in JWKS" do
      _disabled = JwtSigningKeys::HMAC.create!(name: "hmac_disabled_#{SecureRandom.uuid}", enabled: false)
      _expired = JwtSigningKeys::HMAC.create!(name: "hmac_expired_#{SecureRandom.uuid}", expires_at: 1.hour.ago)

      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      expect(body).to have_key("keys")
      kids = body["keys"].map { |k| k["kid"] }

      expect(kids).to include(@test_key.name, @rsa_key.name, @ed25519_key.name, @ecdsa_key.name)
      expect(kids).not_to include(_disabled.name)
      expect(kids).not_to include(_expired.name)
    end

    it "includes required parameters" do
      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      body["keys"].each do |jwk|
        expect(jwk.keys).to include("kty", "use", "kid")
      end
    end

    it "does not leak private keys (HMAC)" do
      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      hmac_jwk = body["keys"].find { |k| k["kid"] == @test_key.name }
      expect(hmac_jwk).to be_present
      expect(hmac_jwk.keys).to_not include("k")
      expect(hmac_jwk["k"]).to be_nil
    end

    it "does not leak private keys (RSA)" do
      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      rsa_jwk = body["keys"].find { |k| k["kid"] == @rsa_key.name }
      expect(rsa_jwk).to be_present
      expect(rsa_jwk).to include("n", "e")
      expect(rsa_jwk.keys).to_not include("d", "p", "q", "dp", "dq", "qi")
    end

    it "does not leak private keys (Ed25519)" do
      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      ed_jwk = body["keys"].find { |k| k["kid"] == @ed25519_key.name }
      expect(ed_jwk).to be_present
      expect(ed_jwk.keys).to include("crv", "x")
      expect(ed_jwk.keys).to_not include("d")
    end

    it "does not leak private keys (ECDSA)" do
      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      ec_jwk = body["keys"].find { |k| k["kid"] == @ecdsa_key.name }
      expect(ec_jwk).to be_present
      expect(ec_jwk.keys).to include("crv", "x", "y")
      expect(ec_jwk.keys).to_not include("d")
    end

    it "returns an expiration timestamp if set" do
      expiry = 1.hour.from_now
      expiring_key = JwtSigningKeys::HMAC.create!(name: "expiring_key_#{SecureRandom.uuid}", expires_at: expiry)
      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      nonexpiring_jwk = body["keys"].find { |k| k["kid"] == @test_key.name }
      expect(nonexpiring_jwk).to be_present
      expect(nonexpiring_jwk.keys).to_not include("exp")

      expiring_jwk = body["keys"].find { |k| k["kid"] == expiring_key.name }
      expect(expiring_jwk).to be_present
      expect(expiring_jwk["exp"]).to eq(expiry.to_i)
    end
  end

  describe "POST /api/v1/jwt/verify" do
    it "returns an error when kid is missing" do
      token = JWT.encode({ data: "test" }, nil, "none")

      post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("error")
      expect(json["error"]).to match(/No kid specified/i)
    end

    it "does not permit algorithm mismatches" do
      token = JWT.encode({ data: "test" }, nil, "none", kid: @test_key.name)

      post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)

      expect(json["status"]).to eq("invalid")
    end

    it "does not accept HS256 algorithms for an RSA key" do
      token = JWT.encode({ data: "test" }, @rsa_key.public_key.to_s, "HS256", kid: @rsa_key.name)

      post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)

      expect(json["status"]).to eq("invalid")
    end

    context "with real signed JWTs" do
      it "accepts a valid HS256 token" do
        header = { alg: "HS256", kid: @test_key.name, typ: "JWT" }
        iss = ENV.fetch('APP_URL', 'https://xivauth.net')
        payload = {
          iss: iss,
          iat: Time.now.to_i,
          exp: (Time.now + 300).to_i,
          data: "hs256 valid"
        }

        token = JWT.encode(payload, @test_key.private_key, "HS256", header)

        post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("valid")
      end
    end

    context "with an audience" do
      it "accepts an audience for its own app" do
        header = { alg: "HS256", kid: @test_key.name, typ: "JWT" }
        payload = {
          iss: ENV.fetch('APP_URL', 'https://xivauth.net'),
          iat: Time.now.to_i,
          exp: (Time.now + 300).to_i,
          aud: "https://xivauth.net/applications/#{oauth_client.application_id}",
          data: "valid"
        }

        token = JWT.encode(payload, @test_key.private_key, "HS256", header)

        post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("valid")
      end

      it "rejects an audience for a different app" do
        another_app = FactoryBot.create(:client_application)

        header = { alg: "HS256", kid: @test_key.name, typ: "JWT" }
        payload = {
          iss: ENV.fetch('APP_URL', 'https://xivauth.net'),
          iat: Time.now.to_i,
          exp: (Time.now + 300).to_i,
          aud: "https://xivauth.net/applications/#{another_app.id}",
          data: "valid"
        }

        token = JWT.encode(payload, @test_key.private_key, "HS256", header)

        post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }
        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json["status"]).to eq("invalid_client")
      end
    end

    context "with an authorized party (azp)" do
      let(:aud_application) { oauth_client.application }
      let(:azp_application) { FactoryBot.create(:client_application) }
      let(:token) do
        header = { alg: "HS256", kid: @test_key.name, typ: "JWT" }
        payload = {
          iss: ENV.fetch('APP_URL', 'https://xivauth.net'),
          iat: Time.now.to_i,
          exp: (Time.now + 300).to_i,
          aud: "https://xivauth.net/applications/#{aud_application.id}",
          azp: "https://xivauth.net/applications/#{azp_application.id}"
        }

        JWT.encode(payload, @test_key.private_key, "HS256", header)
      end

      it "rejects an AZP from a different app" do
        post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }
        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("invalid_client")
      end

      it "accepts an AZP from an allowed app" do
        aud_application.obo_authorizations << azp_application
        aud_application.save

        post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("valid")
      end
    end
  end
end

