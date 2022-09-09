class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name, null: false

      # Each Team can have a single owner that is above the "rules" of the standard user mapping.
      t.references :owner,
                   null: false, index: true, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    create_table :team_memberships, id: :uuid do |t|
      t.references :team, null: false, index: true, type: :uuid
      t.references :user, null: false, index: true, type: :uuid

      t.string :role, null: false

      t.timestamps

      t.index [:team_id, :user_id], unique: true
    end
  end
end
