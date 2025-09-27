require "rails_helper"

RSpec.describe Team, type: :model do
  describe "#all_memberships" do
    let(:u_admin) { FactoryBot.create(:user) }
    let(:u_member) { FactoryBot.create(:user) }
    let(:u_dev) { FactoryBot.create(:user) }

    it "includes direct memberships" do
      team = FactoryBot.create(:team)
      m1 = FactoryBot.create(:team_membership, :admin, team: team, user: u_admin)
      m2 = FactoryBot.create(:team_membership, team: team, user: u_member)

      expect(team.all_memberships).to contain_exactly(m1, m2)
    end

    it "always inherits admin memberships from all ancestors regardless of inherit flag" do
      grandparent = FactoryBot.create(:team, :no_inherit)
      parent = FactoryBot.create(:team, parent: grandparent, inherit_parent_memberships: false)
      child = FactoryBot.create(:team, parent: parent, inherit_parent_memberships: false)

      gp_admin = FactoryBot.create(:team_membership, :admin, team: grandparent, user: u_admin)

      # Child has no direct memberships; should still see ancestor admin
      expect(child.all_memberships).to include(gp_admin)
    end

    it "inherits non-admin memberships only when this team allows it" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent, inherit_parent_memberships: false)

      parent_member = FactoryBot.create(:team_membership, team: parent, user: u_member)

      # When inherit is false, non-admin from parent should NOT be included
      expect(child.all_memberships).not_to include(parent_member)

      # Flip the flag to true and reload behavior
      child.update!(inherit_parent_memberships: true)
      expect(child.all_memberships).to include(parent_member)
    end

    it "respects each ancestor's own non-admin inheritance when cascading" do
      grandparent = FactoryBot.create(:team)
      parent = FactoryBot.create(:team, parent: grandparent, inherit_parent_memberships: false)
      child = FactoryBot.create(:team, parent: parent, inherit_parent_memberships: true)

      gp_member = FactoryBot.create(:team_membership, team: grandparent, user: u_member)
      gp_admin = FactoryBot.create(:team_membership, :admin, team: grandparent, user: u_admin)
      parent_dev = FactoryBot.create(:team_membership, :developer, team: parent, user: u_dev)

      # Because parent has inherit=false, child's inherited non-admins should include only parent's direct non-admin (developer),
      # not grandparent's member. Admin from grandparent should still be inherited.
      expect(child.all_memberships).to include(parent_dev, gp_admin)
      expect(child.all_memberships).not_to include(gp_member)
    end

    it "handles deep trees (3+ levels)" do
      root = FactoryBot.create(:team)
      a = FactoryBot.create(:team, parent: root)
      b = FactoryBot.create(:team, parent: a)
      c = FactoryBot.create(:team, parent: b, inherit_parent_memberships: true)

      root_admin = FactoryBot.create(:team_membership, :admin, team: root, user: u_admin)
      a_member = FactoryBot.create(:team_membership, team: a, user: u_member)
      b_dev = FactoryBot.create(:team_membership, :developer, team: b, user: u_dev)

      # c has no direct memberships but inherits admin from all ancestors and non-admins because its own inherit flag is true
      expect(c.all_memberships).to include(root_admin, a_member, b_dev)

      # Add a direct membership and ensure it's present alongside inherited ones
      c_member = FactoryBot.create(:team_membership, team: c, user: FactoryBot.create(:user))
      expect(c.all_memberships).to include(root_admin, a_member, b_dev, c_member)
    end

    it "deduplicates results, preserving the highest role in the tree" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent, inherit_parent_memberships: true)

      # Same user is member in parent and admin in child
      m1 = FactoryBot.create(:team_membership, team: parent, user: u_admin)
      m2 = FactoryBot.create(:team_membership, :admin, team: child, user: u_admin)

      expect(child.all_memberships).to contain_exactly(m2)
    end

    it "still permits activerecord methods on results" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent)

      m1 = FactoryBot.create(:team_membership, :admin, team: parent, user: u_admin)
      FactoryBot.create(:team_membership, team: child, user: u_member)

      expect(child.all_memberships.count).to eq(2)
      expect(child.all_memberships.admin).to contain_exactly(m1)
      expect(child.all_memberships.find_by(user: u_member).role).to eq("member")
    end
  end

  describe "#readonly?" do
    it "is readonly if id is a special UUID" do
      special_id = "00000000-0000-8000-8f0f-0000deadbeef"
      team = FactoryBot.create(:team, id: special_id)
      expect(team.readonly?).to be true
    end

    it "is not readonly for normal UUIDs" do
      team = FactoryBot.create(:team)
      expect(team.readonly?).to be false
    end
  end
end

FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    inherit_parent_memberships { true }

    trait :no_inherit do
      inherit_parent_memberships { false }
    end

    trait :with_parent do
      association :parent, factory: :team
    end
  end
end

