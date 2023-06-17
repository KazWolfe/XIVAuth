require 'rails_helper'

RSpec.describe CharacterRegistration, type: :model do
  context 'clobbering registrations' do
    before do
      @character = FactoryBot.create(:ffxiv_character)
      @existing_verified = CharacterRegistration.create(
        user: FactoryBot.create(:user),
        character: @character,
        verified_at: DateTime.now
      )
    end

    it 'clobbers the old registration when asked' do
      new_registration = CharacterRegistration.create(
        user: FactoryBot.create(:user),
        character: @character
      )

      new_registration.verify!(clobber: true)
      @existing_verified.reload  # mutated above, need to grab from DB again.

      expect(new_registration.verified?).to be_truthy
      expect(@existing_verified.verified?).to be_falsey
    end

    it 'does not clobber the old registration if not asked' do
      new_registration = CharacterRegistration.create(
        user: FactoryBot.create(:user),
        character: @character
      )

      expect {
        new_registration.verify!(clobber: false)
      }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Character has already been verified.')

      @existing_verified.reload  # possibly mutated above, need to grab from DB again.

      expect(@existing_verified.verified?).to be_truthy
      expect(new_registration.verified?).to be_falsey
    end
  end
end
