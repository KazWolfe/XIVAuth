class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name, null: false

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
