class CreateCharacterRegistrations < ActiveRecord::Migration[7.0]
  def change
    create_table :character_registrations, id: :uuid do |t|
      t.references :user, type: :uuid
      t.references :character, type: :uuid, foreign_key: { to_table: :ffxiv_characters }

      t.datetime :verified_at, null: true

      t.timestamps
    end
  end
end
