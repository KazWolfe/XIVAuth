require 'rails_helper'

RSpec.describe OAuth::PermissiblePolicy, type: :model do
  context 'allow rule present' do
    before do
      @policy = OAuth::PermissiblePolicy.create
      @resource = FactoryBot.create(:ffxiv_character)

      @policy.entries.create(resource: @resource, deny: false)
    end

    it 'allows access to the specified resource' do
      expect(@policy.can_access_resource?(@resource)).to be true
    end

    it 'blocks access to other resources (implicit deny)' do
      another_resource = FactoryBot.create(:ffxiv_character)
      expect(@policy.can_access_resource?(another_resource)).to be false
    end

    it 'blocks access if an explicit deny is specified' do
      @policy.entries.create(resource: @resource, deny: true)
      expect(@policy.can_access_resource?(@resource)).to be false
    end
  end

  context 'deny rule present' do
    before do
      @policy = OAuth::PermissiblePolicy.create
      @resource = FactoryBot.create(:ffxiv_character)

      @policy.entries.create(resource: @resource, deny: true)
    end

    it 'blocks access to the specified resource' do
      expect(@policy.can_access_resource?(@resource)).to be false
    end

    it 'allows access to other resources (no implicit deny)' do
      another_resource = FactoryBot.create(:ffxiv_character)
      expect(@policy.can_access_resource?(another_resource)).to be true
    end

    it 'blocks access even if an explicit allow is specified' do
      @policy.entries.create(resource: @resource, deny: false)
      expect(@policy.can_access_resource?(@resource)).to be false
    end
  end

  context 'no rules present' do
    before do
      @policy = OAuth::PermissiblePolicy.create
    end

    it 'allows access to all resources' do
      resource = FactoryBot.create(:ffxiv_character)
      expect(@policy.can_access_resource?(resource)).to be true
    end

    it 'respects the fallback parameter' do
      resource = FactoryBot.create(:ffxiv_character)
      expect(@policy.can_access_resource?(resource, fallback: true)).to be true
      expect(@policy.can_access_resource?(resource, fallback: false)).to be false
    end
  end
end
