class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false

      # Each Team can have a single owner that is above the "rules" of the standard user mapping.
      t.references :owner, null: false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :team_memberships, id: false, primary_key: [:team_id, :user_id] do |t|
      t.references :team,  null: false, index: true
      t.references :user, null: false, index: true

      t.string :role, null: false

      t.timestamps
    end
  end
end
