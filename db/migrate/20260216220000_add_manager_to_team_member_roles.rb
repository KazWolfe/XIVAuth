class AddManagerToTeamMemberRoles < ActiveRecord::Migration[8.0]
  def up
    execute "ALTER TYPE team_member_roles ADD VALUE 'manager' BEFORE 'developer'"

    # Downgrade any existing invite links targeting admin to developer,
    # since invite links can no longer grant admin or manager roles.
    execute "UPDATE team_invite_links SET target_role = 'developer' WHERE target_role = 'admin'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
