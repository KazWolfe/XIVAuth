require 'rails_helper'

RSpec.describe OAuth::Permissible, type: :model do
  before do
    @user = FactoryBot.create(:random_user)
    @character = FactoryBot.create(:random_character, user: @user)

    @policy_id = SecureRandom.uuid
  end

  it 'supports a single grant under a single policy id' do
    OAuth::Permissible.create(policy_id: @policy_id, resource: @character)
  end

  it 'supports multiple grants of same type under a single policy id' do
    another_character = FactoryBot.create(:random_character, user: @user)

    OAuth::Permissible.create(policy_id: @policy_id, resource: @character)
    OAuth::Permissible.create(policy_id: @policy_id, resource: another_character)
    
    expect(OAuth::Permissible.where(policy_id: @policy_id).count).to eq(2)
    expect(OAuth::Permissible.resources_for_policy_id(@policy_id)).to include(@character, another_character)
  end
end
