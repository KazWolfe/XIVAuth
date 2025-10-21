require "rails_helper"
require "support/oauth_contexts"

RSpec.describe "Api::V1::JwtController", type: :request do
  include_context "oauth:client_credentials"

  # Create HMAC key once for all examples, store in instance variable
  before(:all) do
    @test_key = JwtSigningKeys::HMAC.create!(name: "hmac_spec_#{SecureRandom.uuid}")
  end

  describe "GET /api/v1/jwt/jwks" do
    it "returns only active keys in JWKS" do
      _disabled = JwtSigningKeys::HMAC.create!(name: "hmac_disabled_#{SecureRandom.uuid}", enabled: false)
      _expired = JwtSigningKeys::HMAC.create!(name: "hmac_expired_#{SecureRandom.uuid}", expires_at: 1.hour.ago)

      get api_v1_jwt_jwks_path, headers: { Authorization: bearer_token }
      expect(response).to be_successful

      body = JSON.parse(response.body)
      expect(body).to have_key("keys")
      kids = body["keys"].map { |k| k["kid"] }

      expect(kids).to include(@test_key.name)
      expect(kids).not_to include(_disabled.name)
      expect(kids).not_to include(_expired.name)
    end
  end

  describe "POST /api/v1/jwt/verify" do
    it "returns an error when kid is missing" do
      token = JWT.encode({ data: "test" }, nil, "none")

      post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("error")
      expect(json["error"]).to match(/No kid specified/i)
    end

    it "does not permit algorithm mismatches" do
      token = JWT.encode({ data: "test" }, nil, "none", kid: @test_key.name)

      post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["status"]).to eq("invalid")
    end

    it "does not accept HS256 algorithms for an RSA key" do
      rsa_key = JwtSigningKeys::RSA.create!(name: "rsa_spec_#{SecureRandom.uuid}", size: 1024)
      token = JWT.encode({ data: "test" }, rsa_key.public_key.to_s, "HS256", kid: rsa_key.name)

      post api_v1_jwt_verify_path, params: { token: token }, headers: { Authorization: bearer_token }

      expect(response).to have_http_status(:unprocessable_entity)
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
        expect(response).to have_http_status(:unprocessable_entity)

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
        expect(response).to have_http_status(:unprocessable_entity)
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

