require 'rails_helper'

RSpec.describe Character, type: :model do
  context 'a single character' do
    before do
      @character = FactoryBot.create(:random_character)
    end

    it 'can generate a verification key' do
      verification_key = @character.verification_key

      expect(verification_key).to be_truthy
      expect(verification_key).to start_with('XIVAUTH:')
    end

    it 'defaults to being unverified' do
      expect(@character.verified?).to be_falsey
    end

    it 'can be verified' do
      @character.verify!
      expect(@character.verified?).to be_truthy
    end

    it 'is valid with normal parameters' do
      # As provided by Faker, at least.
      expect(@character).to be_valid
    end
  end

  context 'multiple characters on one user' do
    before do
      @user = FactoryBot.create(:random_user)
    end

    it 'allows creation of multiple characters on one user' do
      character_a = FactoryBot.create(:random_character, user: @user)
      character_b = FactoryBot.create(:random_character, user: @user)

      expect(character_a).to be_valid
      expect(character_b).to be_valid
    end

    it 'prevents one user from registering the same character multiple times' do
      character_a = FactoryBot.create(:random_character, user: @user, lodestone_id: 12345678)
      character_b = FactoryBot.build(:random_character, user: @user, lodestone_id: 12345678)

      expect(character_a).to be_valid
      expect(character_b).to_not be_valid
    end
  end

  context 'a single lodestone_id on multiple users.rb' do
    before do
      @character_a = FactoryBot.create(:random_character, lodestone_id: 12345678)
      @character_b = FactoryBot.create(:random_character, lodestone_id: 12345678)
    end

    it 'allows both characters to be valid' do
      expect(@character_a).to be_valid
      expect(@character_b).to be_valid
    end

    it 'generates different verification codes for different users.rb' do
      # NOTE: May actually fail due to *math shenanigans*, but this is going to be such a rare failure
      # that I'm not particularly concerned if it does.

      key_a = @character_a.verification_key
      key_b = @character_b.verification_key

      expect(key_b).to_not eq(key_a)
    end
  end
end
