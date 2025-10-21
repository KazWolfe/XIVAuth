require 'rails_helper'

RSpec.describe ClientApplication, type: :model do
  describe '#usable_by?' do
    let!(:random_user) { FactoryBot.create(:user) }

    context 'public applications' do
      it 'allows access for any user' do
        app = FactoryBot.create(:client_application, owner:  FactoryBot.create(:user), private: false)

        expect(app.usable_by?(random_user)).to be true
      end

      it 'does not evaluate ACL entries' do
        app = FactoryBot.create(:client_application, owner:  FactoryBot.create(:user), private: false)
        FactoryBot.create(:client_application_acl, application: app, principal: random_user, deny: true)

        expect(app.usable_by?(random_user)).to be true
      end
    end

    context 'unowned application (private)' do
      it "does not allow access without ACL rules" do
        app = FactoryBot.create(:client_application, owner:  nil, private: true)
        expect(app.usable_by?(random_user)).to be false
      end

      it "evaluates ACL rules" do
        app = FactoryBot.create(:client_application, owner:  nil, private: true)
        FactoryBot.create(:client_application_acl, application: app, principal: random_user, deny: false)

        expect(app.usable_by?(random_user)).to be true
      end
    end

    context 'owned by a user (private)' do
      it 'allows access for the owning user even when private' do
        owner = FactoryBot.create(:user)
        app = FactoryBot.create(:client_application, owner: owner, private: true)

        expect(app.usable_by?(owner)).to be true
      end

      it "does not allow access for other users when private" do
        owner = FactoryBot.create(:user)
        app = FactoryBot.create(:client_application, owner: owner, private: true)

        expect(app.usable_by?(random_user)).to be false
      end

      it "allows users to be invited via ACL" do
        owner = FactoryBot.create(:user)
        app = FactoryBot.create(:client_application, owner: owner, private: true)
        FactoryBot.create(:client_application_acl, application: app, principal: random_user, deny: false)

        expect(app.usable_by?(random_user)).to be true
      end

      it "allows the owner even with ACL deny rules" do
        owner = FactoryBot.create(:user)
        app = FactoryBot.create(:client_application, owner: owner, private: true)
        FactoryBot.create(:client_application_acl, application: app, principal: owner, deny: true)

        expect(app.usable_by?(owner)).to be true
      end
    end

    context 'owned by a team (private)' do
      it 'allows access for direct team members even when private' do
        team = FactoryBot.create(:team)
        user = FactoryBot.create(:user)
        FactoryBot.create(:team_membership, team: team, user: user)

        app = FactoryBot.create(:client_application, owner: team, private: true)

        expect(app.usable_by?(user)).to be true
      end

      it "does not allow team members to be denied via ACL, even directly" do
        team = FactoryBot.create(:team)
        user = FactoryBot.create(:user)
        FactoryBot.create(:team_membership, team: team, user: user)

        app = FactoryBot.create(:client_application, owner: team, private: true)
        FactoryBot.create(:client_application_acl, application: app, principal: user, deny: true)

        expect(app.usable_by?(user)).to be true
      end

      it "does not allow access for other users when private" do
        team = FactoryBot.create(:team)
        FactoryBot.create(:team_membership, team: team, user: FactoryBot.create(:user))
        app = FactoryBot.create(:client_application, owner: team, private: true)

        expect(app.usable_by?(random_user)).to be false
      end

      it "allows the owning team members even with ACL deny rules" do
        team = FactoryBot.create(:team)
        user = FactoryBot.create(:user)
        FactoryBot.create(:team_membership, team: team, user: user)

        app = FactoryBot.create(:client_application, owner: team, private: true)
        FactoryBot.create(:client_application_acl, application: app, principal: team, deny: true)

        expect(app.usable_by?(user)).to be true
      end

      it "allows admins of the owning parent team access ignoring ACL" do
        parent_team = FactoryBot.create(:team)
        admin_user = FactoryBot.create(:user)
        FactoryBot.create(:team_membership, team: parent_team, user: admin_user, role: 'admin')

        child_team = FactoryBot.create(:team, parent: parent_team)
        child_user = FactoryBot.create(:user)
        FactoryBot.create(:team_membership, team: child_team, user: child_user)

        app = FactoryBot.create(:client_application, owner: child_team, private: true)

        expect(app.usable_by?(admin_user)).to be true
      end
    end

    context 'team invited to app via ACL' do
      let!(:owner_user) { FactoryBot.create(:user) }
      let!(:parent_team) { FactoryBot.create(:team) }
      let!(:child_team) { FactoryBot.create(:team, parent: parent_team) }
      let!(:grandchild_team) { FactoryBot.create(:team, parent: child_team) }
      let!(:noninherited_team) { FactoryBot.create(:team, :no_inherit, parent: parent_team) }

      let!(:direct_member) { FactoryBot.create(:user) }
      let!(:parent_member) { FactoryBot.create(:user) }
      let!(:child_member) { FactoryBot.create(:user) }
      let!(:grandchild_member) { FactoryBot.create(:user) }

      let!(:direct_membership) { FactoryBot.create(:team_membership, team: parent_team, user: direct_member) }
      let!(:parent_membership) { FactoryBot.create(:team_membership, team: parent_team, user: parent_member) }
      let!(:child_membership) { FactoryBot.create(:team_membership, team: child_team, user: child_member) }
      let!(:grandchild_membership) { FactoryBot.create(:team_membership, team: grandchild_team, user: grandchild_member) }

      let!(:app) { FactoryBot.create(:client_application, owner: owner_user, private: true) }

      it "allows a team's direct members when the team is on the ACL" do
        FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: false)

        expect(app.usable_by?(direct_member)).to be true
      end

      it "allows access to members of parent teams if inheritance is enabled" do
        FactoryBot.create(:client_application_acl, application: app, principal: child_team, deny: false)

        expect(app.usable_by?(parent_member)).to be true
      end

      it "blocks access to members of parent teams if inheritance is disabled" do
        FactoryBot.create(:client_application_acl, application: app, principal: noninherited_team, deny: false)

        expect(app.usable_by?(parent_member)).to be false
      end

      it "allows access to admins of parent teams regardless of team inheritance" do
        admin_member = FactoryBot.create(:user)
        FactoryBot.create(:team_membership, team: parent_team, user: admin_member, role: 'admin')
        FactoryBot.create(:client_application_acl, application: app, principal: noninherited_team, deny: false)

        expect(app.usable_by?(admin_member)).to be true
      end

      it "allows access to child team members when include_team_descendants is true" do
        FactoryBot.create(:client_application_acl, application: app, principal: parent_team, include_team_descendants: true, deny: false)

        expect(app.usable_by?(child_member)).to be true
      end

      it "does not allow access to child team members when include_team_descendants is false" do
        FactoryBot.create(:client_application_acl, application: app, principal: parent_team, include_team_descendants: false, deny: false)

        expect(app.usable_by?(child_member)).to be false
      end

      it "still includes parent team members when include_team_descendants is false" do
        FactoryBot.create(:client_application_acl, application: app, principal: child_team, include_team_descendants: false, deny: false)

        expect(app.usable_by?(parent_member)).to be true
        expect(app.usable_by?(grandchild_member)).to be false
      end

      it "can process mixed team and user ACLs" do
        FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: false)
        FactoryBot.create(:client_application_acl, application: app, principal: random_user, deny: false)

        expect(app.usable_by?(direct_member)).to be true
        expect(app.usable_by?(random_user)).to be true
      end

      describe "deny rules on ACL" do
        it "prioritizes a user deny above a team allow" do
          FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: false)
          FactoryBot.create(:client_application_acl, application: app, principal: direct_member, deny: true)

          expect(app.usable_by?(direct_member)).to be false
        end

        it "prioritizes a user allow above a team deny" do
          FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: true)
          FactoryBot.create(:client_application_acl, application: app, principal: direct_member, deny: false)

          expect(app.usable_by?(direct_member)).to be true
        end

        it "prioritizes a team deny even if the parent team has include_team_descendants enabled" do
          FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: false, include_team_descendants: true)
          FactoryBot.create(:client_application_acl, application: app, principal: child_team, deny: true)

          expect(app.usable_by?(child_member)).to be false
        end

        it "ignores inherited members for child team denies" do
          FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: false, include_team_descendants: true)
          FactoryBot.create(:client_application_acl, application: app, principal: child_team, deny: true)

          expect(app.usable_by?(parent_member)).to be true
        end

        it "allows child members if include_team_descendants not set on deny ACL" do
          FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: false, include_team_descendants: true)
          FactoryBot.create(:client_application_acl, application: app, principal: child_team, deny: true)

          expect(app.usable_by?(grandchild_member)).to be true
        end

        it "blocks child members if include_team_descendants set on deny ACL" do
          FactoryBot.create(:client_application_acl, application: app, principal: parent_team, deny: false, include_team_descendants: true)
          FactoryBot.create(:client_application_acl, application: app, principal: child_team, deny: true, include_team_descendants: true)

          expect(app.usable_by?(grandchild_member)).to be false
        end
      end

      describe "ACL robustness" do
        it "properly skips a missing team reference" do
          missing_team = FactoryBot.create(:team)
          FactoryBot.create(:team_membership, team: missing_team, user: random_user)

          FactoryBot.create(:client_application_acl, application: app, principal: missing_team, deny: false)
          expect(app.usable_by?(random_user)).to be true

          missing_team.destroy!

          expect(app.usable_by?(random_user)).to be false
        end
      end
    end
  end

  describe '#obo_authorizations' do
    it "allows an app to grant an On-Behalf-Of authorization to another app" do
      first = FactoryBot.create(:client_application)
      second = FactoryBot.create(:client_application)
      first.obo_authorizations << second

      expect(first.obo_authorizations).to include(second)
      expect(second.obo_authorizations).to_not include(first)

      expect(first).to be_valid
      expect(second).to be_valid

      expect(first.obo_authorizations.exists?(second.id)).to be true
    end

    it "allows circular OBO grants" do
      first = FactoryBot.create(:client_application)
      second = FactoryBot.create(:client_application)
      first.obo_authorizations << second
      second.obo_authorizations << first

      expect(first.obo_authorizations).to include(second)
      expect(second.obo_authorizations).to include(first)

      expect(first).to be_valid
      expect(second).to be_valid
    end
  end
end
