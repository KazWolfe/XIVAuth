require 'rails_helper'

RSpec.describe User, type: :model do
  context 'with an empty password' do
    before do
      @user = FactoryBot.build(:user, encrypted_password: nil)
    end

    it 'properly reports an empty password' do
      # Sanity test to ensure FactoryBot isn't going to cause problems for us.
      expect(@user.encrypted_password).to be_nil
      expect(@user.has_password?).to be(false)
    end

    it 'cleanly fails validation of any input password' do
      expect(@user.valid_password?("")).to be(false)
      expect(@user.valid_password?(nil)).to be(false)
      expect(@user.valid_password?("P@ssw0rd!")).to be(false)
    end
  end
end