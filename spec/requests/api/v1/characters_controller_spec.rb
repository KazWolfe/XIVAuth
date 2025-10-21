require "rails_helper"
require "support/without_detailed_exceptions"

RSpec.describe "Api::V1::CharactersControllers", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:oauth_client) { FactoryBot.create(:oauth_client) }
  let(:character) { FactoryBot.create(:ffxiv_character) }

  context "using the character:all scope" do
    let(:oauth_token) do
      OAuth::AccessToken.create(application: oauth_client, resource_owner: user, scopes: "character:all")
    end

    context "GET /characters" do
      it "returns a verified character when present" do
        FactoryBot.create(:verified_registration, character:, user:)

        get api_v1_characters_path, headers: { 'Authorization': "Bearer #{oauth_token.token}" }, as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        character_data = json.first

        expect(character_data["lodestone_id"]).to eq(character.lodestone_id)
        expect(character_data["name"]).to eq(character.name)
      end

      it "does not return an unverified character" do
        FactoryBot.create(:character_registration, character:, user:)

        get api_v1_characters_path, headers: { 'Authorization': "Bearer #{oauth_token.token}" }, as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)

        expect(json).to be_empty
      end

      it "allows filtering by parameters" do
        FactoryBot.create(:verified_registration, character:, user:)
        3.times do
          FactoryBot.create(:verified_registration, user:)
        end

        get api_v1_characters_path,
            params: { name: character.name },
            headers: { 'Authorization': "Bearer #{oauth_token.token}" },
            as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)

        expect(json.count).to eq(1)
        expect(json.first["lodestone_id"]).to eq(character.lodestone_id)
      end
    end

    context "GET /characters/:lodestone_id" do
      it "allows retrieving a verified character by id" do
        FactoryBot.create(:verified_registration, character:, user:)

        get api_v1_character_path(lodestone_id: character.lodestone_id),
            headers: { 'Authorization': "Bearer #{oauth_token.token}" }, as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)

        expect(json["lodestone_id"]).to eq(character.lodestone_id)
      end

      it "does not allow retrieving an unverified character by id" do
        FactoryBot.create(:character_registration, character:, user:)

        without_detailed_exceptions do
          get api_v1_character_path(lodestone_id: character.lodestone_id),
              headers: { 'Authorization': "Bearer #{oauth_token.token}" }, as: :json
        end

        expect(response).to have_http_status(404)
      end

      it "does not allow retrieving a character owned by another user" do
        another_user = FactoryBot.create(:user)
        another_character = FactoryBot.create(:ffxiv_character)
        FactoryBot.create(:verified_registration, character: another_character, user: another_user)

        without_detailed_exceptions do
          get api_v1_character_path(lodestone_id: another_character.lodestone_id),
              headers: { 'Authorization': "Bearer #{oauth_token.token}" }, as: :json
        end

        expect(response).to have_http_status(404)
      end
    end

    context "POST /characters" do
      it "returns HTTP 403" do
        without_detailed_exceptions do
          post api_v1_characters_path,
               params: { 'lodestone_id': "12345678" },
               headers: { 'Authorization': "Bearer #{oauth_token.token}" },
               as: :json
        end

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "PATCH /characters/:lodestone_id" do
      let(:registration) { FactoryBot.create(:verified_registration, character:, user:) }

      it "returns HTTP 403" do
        without_detailed_exceptions do
          patch api_v1_character_path(lodestone_id: character.lodestone_id),
                params: { 'content_id': "22446688" },
                headers: { 'Authorization': "Bearer #{oauth_token.token}" },
                as: :json
        end

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "DELETE /characters/:lodestone_id" do
      it "returns HTTP 403" do
        FactoryBot.create(:verified_registration, character:, user:)

        delete api_v1_character_path(lodestone_id: character.lodestone_id),
               headers: { 'Authorization': "Bearer #{oauth_token.token}" },
               as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "using the character:manage scope" do
    let(:oauth_token) do
      OAuth::AccessToken.create(application: oauth_client, resource_owner: user, scopes: "character:manage")
    end

    context "GET /characters" do
      it "returns unverified characters" do
        registration = FactoryBot.create(:character_registration, character:, user:)

        get api_v1_characters_path, headers: { 'Authorization': "Bearer #{oauth_token.token}" }, as: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        character_data = json.first

        # validate presence of internal fields
        expect(character_data["__crid"]).to eq(registration.id)
        expect(character_data["__cid"]).to eq(character.id)

        expect(character_data["lodestone_id"]).to eq(character.lodestone_id)
        expect(character_data["name"]).to eq(character.name)

        expect(character_data["verified_at"]).to be_nil
        expect(character_data["verified"]).to be(false)
      end
    end

    context "POST /characters" do
      it "creates a new character from a lodestone id" do
        post api_v1_characters_path, params: { lodestone_id: "12345678" },
             headers: { 'Authorization': "Bearer #{oauth_token.token}" },
             as: :json

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["lodestone_id"]).to eq("12345678")
        expect(json["verified"]).to be(false)
        expect(json["verification_key"]).to be_present

        db_character = FFXIV::Character.find_by_lodestone_id("12345678")
        registration = CharacterRegistration.find_by(user: user, character: db_character)

        expect(db_character).to be_persisted
        expect(registration).to be_persisted
      end

      xit "creates a new character from a name/world" do
      end
    end

    context "GET /characters/:lodestone_id" do
      it "allows fetching a character (with extended data)" do
        FactoryBot.create(:character_registration, character:, user:)

        get api_v1_character_path(lodestone_id: character.lodestone_id),
            headers: { 'Authorization': "Bearer #{oauth_token.token}" },
            as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)

        expect(json["lodestone_id"]).to eq(character.lodestone_id)
        expect(json["verification_key"]).to be_present
      end
    end

    context "DELETE /characters/:lodestone_id" do
      it "can delete a character" do
        FactoryBot.create(:verified_registration, character:, user:)

        delete api_v1_character_path(lodestone_id: character.lodestone_id),
               headers: { 'Authorization': "Bearer #{oauth_token.token}" },
               as: :json

        expect(response).to have_http_status(:no_content)

        # ensure only the registration is deleted, not the character
        expect(character.reload).to be_persisted
        expect(CharacterRegistration.find_by(character:, user:)).to be_nil
      end

      it "can't delete another user's character" do
        another_user = FactoryBot.create(:user)
        another_character = FactoryBot.create(:ffxiv_character)
        FactoryBot.create(:verified_registration, character: another_character, user: another_user)

        without_detailed_exceptions do
          delete api_v1_character_path(lodestone_id: character.lodestone_id),
                 headers: { 'Authorization': "Bearer #{oauth_token.token}" },
                 as: :json
        end

        expect(response).to have_http_status(:not_found)
        expect(CharacterRegistration.find_by(character: another_character, user: another_user)).to be_persisted
      end
    end

    context "PATCH /characters/:lodestone_id" do
      before do
        FactoryBot.create(:verified_registration, character:, user:)
      end

      it "can edit a character's Content ID" do
        new_content_id = "a1b2c3d4"

        patch api_v1_character_path(lodestone_id: character.lodestone_id),
              params: { 'content_id': new_content_id },
              headers: { 'Authorization': "Bearer #{oauth_token.token}" },
              as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["content_id"]).to eq(new_content_id)

        character.reload
        expect(character).to be_persisted
        expect(character.content_id).to eq(new_content_id)
      end

      it "can't edit a character's name" do
        patch api_v1_character_path(lodestone_id: character.lodestone_id),
              params: { 'name': "Test Failure" },
              headers: { 'Authorization': "Bearer #{oauth_token.token}" },
              as: :json

        # FIXME: This should return 422 here.
        expect(response).to have_http_status(:ok)

        character.reload
        expect(character.name).to_not eq("Test Failure")
      end

      it "can't edit another user's character" do
        another_user = FactoryBot.create(:user)
        another_character = FactoryBot.create(:ffxiv_character)
        FactoryBot.create(:verified_registration, character: another_character, user: another_user)

        without_detailed_exceptions do
          patch api_v1_character_path(lodestone_id: another_character.lodestone_id),
                params: { 'content_id': "12345678" },
                headers: { 'Authorization': "Bearer #{oauth_token.token}" },
                as: :json
        end

        expect(response).to have_http_status(:not_found)

        another_character.reload
        expect(another_character.content_id).to_not eq("12345678")
      end
    end
  end
end
