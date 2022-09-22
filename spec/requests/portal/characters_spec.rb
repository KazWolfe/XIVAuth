require 'rails_helper'

RSpec.describe "Portal::Characters", type: :request do
  describe "GET /index without authentication" do
    it "redirects to login" do
      get characters_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /index.json without authentication" do
    it "generates a 401" do
      get characters_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /index with authentication" do
    before do
      @user = FactoryBot.create(:random_user)
      @user.confirm
      sign_in @user
    end

    it "should return a success" do
      get characters_path
      expect(response).to have_http_status(:ok)
    end

    it "should list registered characters" do
      character_names = []
      3.times do
        character = FactoryBot.create(:random_character, user: @user)
        character_names.push(character.character_name)
      end

      get characters_path
      character_names.each do |chara|
        expect(response.body).to include(chara)
      end
    end

    it "should not list other users' characters" do
      another_character = FactoryBot.create(:random_character)

      get characters_path
      expect(response.body).to_not include(another_character.character_name)
    end

    it "should hide the create character button after a certain number of characters" do
      5.times do
        FactoryBot.create(:random_character, user: @user)
      end

      get characters_path
      expect(response.body).to_not include new_character_patha
    end

    xit "should not list other users' characters (even as admin)" do
      # Need to figure out roles
    end
  end

  describe "get /show/:id.json with authentication" do
    before do
      @character = FactoryBot.create(:random_character)
      @character.user.confirm
      sign_in @character.user
    end

    it "should allow retrieving the character" do
      get character_path(@character.id), as: :json

      parsed_body = JSON.parse(response.body)

      expect(parsed_body['character_name']).to eq(@character.character_name)
    end

    it "should not allow retrieving a character owned by another user" do
      another_character = FactoryBot.create(:random_character)

      # ToDo: This should really test for status code 403, but I'm honestly unsure of how to do that.
      expect { get character_path(another_character.id) }.to raise_error(CanCan::AccessDenied)
    end

    xit "should not allow retrieving a character owned by another user (even as admin)" do
      # Need to figure out roles
    end
  end

end
