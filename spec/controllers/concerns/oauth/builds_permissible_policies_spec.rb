require "rails_helper"

RSpec.describe OAuth::BuildsPermissiblePolicies do
  let(:user) { FactoryBot.create(:user) }

  let!(:char_a) { FactoryBot.create(:verified_registration, user: user) }
  let!(:char_b) { FactoryBot.create(:verified_registration, user: user) }
  let!(:ident_a) { FactoryBot.create(:users_social_identity, user: user) }
  let!(:ident_b) { FactoryBot.create(:users_social_identity, user: user, provider: "github") }

  # Minimal stand-in for the controller context the concern is mixed into.
  let(:builder) do
    Class.new do
      include OAuth::BuildsPermissiblePolicies

      attr_accessor :params, :current_resource_owner

      delegate :logger, to: :Rails
    end.new.tap { |b| b.current_resource_owner = user }
  end

  # @param characters [Array<String>] lodestone_ids selected on the consent screen
  # @param identities [Array<String>] social identity UUIDs selected on the consent screen
  def build_policy(characters: [], identities: [], share_new_characters: false, share_new_identities: false)
    builder.params = ActionController::Parameters.new(
      {
        characters: characters,
        social_identities: identities,
        share_new_characters: share_new_characters.presence,
        share_new_identities: share_new_identities.presence
      }.compact
    )

    builder.build_permissible_policy
  end

  def rules_for(policy, type)
    policy.rules.select { |r| r.resource_type == type }
  end

  def null_rules_for(policy, type)
    rules_for(policy, type).select { |r| r.resource_id.nil? }
  end

  describe "#build_character_policy_rules" do
    it "emits a null record when nothing was selected" do
      policy = build_policy(characters: [])

      expect(null_rules_for(policy, "CharacterRegistration"))
        .to contain_exactly(have_attributes(resource_type: "CharacterRegistration", resource_id: nil, deny: false))
    end

    it "emits allow rules and no null record when a selection was made" do
      policy = build_policy(characters: [char_a.character.lodestone_id.to_s])

      expect(rules_for(policy, "CharacterRegistration"))
        .to contain_exactly(have_attributes(resource_id: char_a.id, deny: false))
    end

    it "emits no rules at all when sharing everything including future records" do
      policy = build_policy(characters: [char_a, char_b].map { |c| c.character.lodestone_id.to_s },
                            share_new_characters: true)

      expect(rules_for(policy, "CharacterRegistration")).to be_empty
    end

    it "emits deny rules for the unselected records in share-new mode" do
      policy = build_policy(characters: [char_a.character.lodestone_id.to_s], share_new_characters: true)

      expect(rules_for(policy, "CharacterRegistration"))
        .to contain_exactly(have_attributes(resource_id: char_b.id, deny: true))
    end

    it "emits a null record when the selection names records the user does not own" do
      other = FactoryBot.create(:verified_registration)
      policy = build_policy(characters: [other.character.lodestone_id.to_s])

      expect(null_rules_for(policy, "CharacterRegistration")).to be_present
      expect(rules_for(policy, "CharacterRegistration").map(&:resource_id)).not_to include(other.id)
    end
  end

  describe "#build_identity_policy_rules" do
    it "emits a null record when nothing was selected" do
      policy = build_policy(identities: [])

      expect(null_rules_for(policy, "User::SocialIdentity"))
        .to contain_exactly(have_attributes(resource_type: "User::SocialIdentity", resource_id: nil, deny: false))
    end

    it "emits allow rules and no null record when a selection was made" do
      policy = build_policy(identities: [ident_a.id])

      expect(rules_for(policy, "User::SocialIdentity"))
        .to contain_exactly(have_attributes(resource_id: ident_a.id, deny: false))
    end

    it "emits no rules at all when sharing everything including future records" do
      policy = build_policy(identities: [ident_a, ident_b].map(&:id), share_new_identities: true)

      expect(rules_for(policy, "User::SocialIdentity")).to be_empty
    end

    it "emits deny rules for the unselected records in share-new mode" do
      policy = build_policy(identities: [ident_a.id], share_new_identities: true)

      expect(rules_for(policy, "User::SocialIdentity"))
        .to contain_exactly(have_attributes(resource_id: ident_b.id, deny: true))
    end

    it "emits a null record when the selection names records the user does not own" do
      other = FactoryBot.create(:users_social_identity)
      policy = build_policy(identities: [other.id])

      expect(null_rules_for(policy, "User::SocialIdentity")).to be_present
      expect(rules_for(policy, "User::SocialIdentity").map(&:resource_id)).not_to include(other.id)
    end
  end

  describe "#build_permissible_policy" do
    it "emits a null record for every type when nothing at all was selected" do
      # Each type is built independently, so a one-sided null record would silently
      # leave the other type on implicit allow.
      policy = build_policy(characters: [], identities: [])

      expect(policy.rules.select { |r| r.resource_id.nil? }.map(&:resource_type))
        .to contain_exactly("CharacterRegistration", "User::SocialIdentity")
    end

    it "produces a persistable, non-empty policy when nothing was selected" do
      # OAuth::AuthorizationsController only attaches a policy `if policy.rules.present?`,
      # so an all-empty consent must still yield rules or it is dropped and the token
      # ends up with no policy at all.
      policy = build_policy(characters: [], identities: [])

      expect(policy.rules).to be_present
      expect { policy.save! }.not_to raise_error
    end
  end
end
