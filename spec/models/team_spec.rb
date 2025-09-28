require "rails_helper"

RSpec.describe Team, type: :model do
  describe "#active_memberships" do
    it "does not return blocked or invited roles" do
      team = FactoryBot.create(:team)
      blocked_user = FactoryBot.create(:user)
      invited_user = FactoryBot.create(:user)
      active_user = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, :blocked, team: team, user: blocked_user)
      FactoryBot.create(:team_membership, :invited, team: team, user: invited_user)
      active_membership = FactoryBot.create(:team_membership, team: team, user: active_user)

      expect(team.active_memberships).to contain_exactly(active_membership)
    end
  end
  
  describe "#antecedent_memberships" do
    let(:u_admin) { FactoryBot.create(:user) }
    let(:u_member) { FactoryBot.create(:user) }
    let(:u_dev) { FactoryBot.create(:user) }

    it "excludes own direct memberships (ancestors only)" do
      team = FactoryBot.create(:team)
      m1 = FactoryBot.create(:team_membership, :admin, team: team, user: u_admin)
      m2 = FactoryBot.create(:team_membership, team: team, user: u_member)

      expect(team.antecedent_memberships).to be_empty
      expect(team.antecedent_memberships).not_to include(m1, m2)
    end

    it "always inherits admin memberships from all ancestors regardless of inherit flag" do
      grandparent = FactoryBot.create(:team, :no_inherit)
      parent = FactoryBot.create(:team, parent: grandparent, inherit_parent_memberships: false)
      child = FactoryBot.create(:team, parent: parent, inherit_parent_memberships: false)

      gp_admin = FactoryBot.create(:team_membership, :admin, team: grandparent, user: u_admin)

      # Child has no direct memberships; should still see ancestor admin
      expect(child.antecedent_memberships).to include(gp_admin)
    end

    it "inherits non-admin memberships only when this team allows it" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent, inherit_parent_memberships: false)

      parent_member = FactoryBot.create(:team_membership, team: parent, user: u_member)

      # When inherit is false, non-admin from parent should NOT be included
      expect(child.antecedent_memberships).not_to include(parent_member)

      # Flip the flag to true and reload behavior
      child.update!(inherit_parent_memberships: true)
      expect(child.antecedent_memberships).to include(parent_member)
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
      expect(child.antecedent_memberships).to include(parent_dev, gp_admin)
      expect(child.antecedent_memberships).not_to include(gp_member)
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
      expect(c.antecedent_memberships).to include(root_admin, a_member, b_dev)

      # Add a direct membership and ensure it's still excluded (own direct membership)
      c_member = FactoryBot.create(:team_membership, team: c, user: FactoryBot.create(:user))
      expect(c.antecedent_memberships).to include(root_admin, a_member, b_dev)
      expect(c.antecedent_memberships).not_to include(c_member)
    end

    it "contains duplicate memberships in the tree" do
      grandparent = FactoryBot.create(:team)
      parent = FactoryBot.create(:team, parent: grandparent, inherit_parent_memberships: true)
      child = FactoryBot.create(:team, parent: parent, inherit_parent_memberships: true)

      parent_member = FactoryBot.create(:team_membership, team: parent, user: u_admin)
      gp_admin = FactoryBot.create(:team_membership, :admin, team: grandparent, user: u_admin)

      expect(child.antecedent_memberships).to contain_exactly(parent_member, gp_admin)
    end

    it "still permits activerecord methods on results" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent)

      m1 = FactoryBot.create(:team_membership, :admin, team: parent, user: u_admin)
      FactoryBot.create(:team_membership, team: child, user: u_member)

      expect(child.antecedent_memberships.count).to eq(1)
      expect(child.antecedent_memberships.admins).to contain_exactly(m1)
      expect(child.antecedent_memberships.find_by(user: u_member)).to be_nil
    end

    it "should not include blocked or invited roles from ancestors" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent)

      blocked_user = FactoryBot.create(:user)
      invited_user = FactoryBot.create(:user)
      active_user = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, :blocked, team: parent, user: blocked_user)
      FactoryBot.create(:team_membership, :invited, team: parent, user: invited_user)
      active_membership = FactoryBot.create(:team_membership, team: parent, user: active_user)

      expect(child.antecedent_memberships).to contain_exactly(active_membership)
    end
  end

  describe "#antecedent_members" do
    it "returns a list of member users from antecedents only (excludes own)" do
      parent = FactoryBot.create(:team)
      team = FactoryBot.create(:team, parent: parent)
      u1 = FactoryBot.create(:user)
      u2 = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, :admin, team: parent, user: u1)
      FactoryBot.create(:team_membership, team: team, user: u2) # own direct, should be excluded

      expect(team.antecedent_members).to contain_exactly(u1)
    end

    it "does not return duplicates if user is in multiple ancestor teams" do
      grandparent = FactoryBot.create(:team)
      parent = FactoryBot.create(:team, parent: grandparent)
      team = FactoryBot.create(:team, parent: parent)

      u_shared = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: grandparent, user: u_shared)
      FactoryBot.create(:team_membership, team: parent, user: u_shared)

      expect(team.antecedent_members).to contain_exactly(u_shared)
    end
  end

  describe "#descendant_memberships" do
    it "reads memberships from deep trees (3+) excluding own" do
      root = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: root)
      grandchild = FactoryBot.create(:team, parent: child)

      FactoryBot.create(:team_membership, team: root, user: FactoryBot.create(:user))
      m2 = FactoryBot.create(:team_membership, team: child, user: FactoryBot.create(:user))
      m3 = FactoryBot.create(:team_membership, team: grandchild, user: FactoryBot.create(:user))

      expect(root.descendant_memberships).to contain_exactly(m2, m3)
      expect(child.descendant_memberships).to contain_exactly(m3)
      expect(grandchild.descendant_memberships).to be_empty
    end

    it "is empty if no descendants" do
      team = FactoryBot.create(:team)
      FactoryBot.create(:team_membership, team: team, user: FactoryBot.create(:user))

      expect(team.descendant_memberships).to be_empty
    end

    it "reads memberships across multiple children" do
      parent = FactoryBot.create(:team)
      child1 = FactoryBot.create(:team, parent: parent)
      child2 = FactoryBot.create(:team, parent: parent)

      m1 = FactoryBot.create(:team_membership, team: child1, user: FactoryBot.create(:user))
      m2 = FactoryBot.create(:team_membership, team: child2, user: FactoryBot.create(:user))

      expect(parent.descendant_memberships).to contain_exactly(m1, m2)
    end
    
    it "shoud not include blocked or invited roles from descendants" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent)

      blocked_user = FactoryBot.create(:user)
      invited_user = FactoryBot.create(:user)
      active_user = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, :blocked, team: child, user: blocked_user)
      FactoryBot.create(:team_membership, :invited, team: child, user: invited_user)
      active_membership = FactoryBot.create(:team_membership, team: child, user: active_user)

      expect(parent.descendant_memberships).to contain_exactly(active_membership)
    end
  end

  describe "#descendant_members" do
    it "returns a list of member users from descendants only (excludes own)" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent)

      u1 = FactoryBot.create(:user)
      u2 = FactoryBot.create(:user)
      u3 = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: parent, user: u1) # own, excluded
      FactoryBot.create(:team_membership, team: child, user: u2)
      FactoryBot.create(:team_membership, team: child, user: u3)

      expect(parent.descendant_members).to contain_exactly(u2, u3)
      expect(child.descendant_members).to be_empty
    end

    it "does not return duplicates if user is in multiple descendant teams" do
      parent = FactoryBot.create(:team)
      child1 = FactoryBot.create(:team, parent: parent)
      child2 = FactoryBot.create(:team, parent: parent)

      u_shared = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: child1, user: u_shared)
      FactoryBot.create(:team_membership, team: child2, user: u_shared)

      expect(parent.descendant_members).to contain_exactly(u_shared)
    end

    it "allows activerecord methods on results" do
      parent = FactoryBot.create(:team)
      child = FactoryBot.create(:team, parent: parent)

      u1 = FactoryBot.create(:user)
      u2 = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: parent, user: u1) # own, excluded
      FactoryBot.create(:team_membership, team: child, user: u2)

      expect(parent.descendant_members.count).to eq(1)
      expect(parent.descendant_members.find_by(id: u1.id)).to be_nil
      expect(parent.descendant_members.find_by(id: u2.id)).to eq(u2)
    end
  end

  describe "#all_members" do
    it "includes antecedent and direct members by default" do
      parent = FactoryBot.create(:team)
      team = FactoryBot.create(:team, parent: parent)

      u1 = FactoryBot.create(:user)
      u2 = FactoryBot.create(:user)
      u3 = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: parent, user: u1) # antecedent
      FactoryBot.create(:team_membership, team: team, user: u2)   # direct
      FactoryBot.create(:team_membership, team: FactoryBot.create(:team), user: u3) # unrelated

      expect(team.all_members).to contain_exactly(u1, u2)
    end

    it "includes descendant members when include_descendants is true" do
      parent = FactoryBot.create(:team)
      team = FactoryBot.create(:team, parent: parent)
      child = FactoryBot.create(:team, parent: team)

      u1 = FactoryBot.create(:user)
      u2 = FactoryBot.create(:user)
      u3 = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: parent, user: u1) # antecedent
      FactoryBot.create(:team_membership, team: team, user: u2)   # direct
      FactoryBot.create(:team_membership, team: child, user: u3)  # descendant

      expect(team.all_members(include_descendants: true)).to contain_exactly(u1, u2, u3)
    end

    it "does not return duplicates if user is in multiple related teams" do
      parent = FactoryBot.create(:team)
      team = FactoryBot.create(:team, parent: parent)
      child = FactoryBot.create(:team, parent: team)

      u_shared = FactoryBot.create(:user)
      u_child = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: parent, user: u_shared)
      FactoryBot.create(:team_membership, team: team, user: u_shared)
      FactoryBot.create(:team_membership, team: team, user: u_child)
      FactoryBot.create(:team_membership, team: child, user: u_child)

      expect(team.all_members(include_descendants: true)).to contain_exactly(u_shared, u_child)
    end

    it "supports activerecord chaining" do
      parent = FactoryBot.create(:team)
      team = FactoryBot.create(:team, parent: parent)

      u_1 = FactoryBot.create(:user)
      u_2 = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, team: parent, user: u_1)
      FactoryBot.create(:team_membership, team: team, user: u_2)

      expect(team.all_members.count).to eql(2)
      expect(team.all_members.find(u_2.id)).to eql(u_2)
    end
    
    it "should not include blocked or invited roles from antecedents or descendants" do
      parent = FactoryBot.create(:team)
      team = FactoryBot.create(:team, parent: parent)
      child = FactoryBot.create(:team, parent: team)

      blocked_user = FactoryBot.create(:user)
      invited_user = FactoryBot.create(:user)
      active_user_antecedent = FactoryBot.create(:user)
      active_user_direct = FactoryBot.create(:user)
      active_user_descendant = FactoryBot.create(:user)

      FactoryBot.create(:team_membership, :blocked, team: parent, user: blocked_user)
      FactoryBot.create(:team_membership, :invited, team: parent, user: invited_user)
      FactoryBot.create(:team_membership, team: parent, user: active_user_antecedent)
      FactoryBot.create(:team_membership, team: team, user: active_user_direct)
      FactoryBot.create(:team_membership, team: child, user: active_user_descendant)

      expect(team.all_members(include_descendants: true)).to contain_exactly(active_user_antecedent, active_user_direct, active_user_descendant)
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

    it "is not readonly for new records even with special ID" do
      special_id = "00000000-0000-8000-8f0f-0000deadbeef"
      team = FactoryBot.build(:team, id: special_id)
      expect(team.readonly?).to be false
    end

    it "still supports records being manually marked as readonly" do
      team = FactoryBot.create(:team)
      expect(team.readonly?).to be false

      team.readonly!
      expect(team.readonly?).to be true
    end
  end
end
