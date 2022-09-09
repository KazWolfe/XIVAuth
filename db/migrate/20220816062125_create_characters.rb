class CreateCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :characters, id: :uuid do |t|
      # Not actually unique, we will allow multiple users to try to claim the same character.
      t.integer :lodestone_id, index: { unique: false }, null: false

      t.references :user, null: false, foreign_key: true, type: :uuid

      # For in-game logins, we can additionally track by content ID. This does *not* replace lodestone id!
      t.bigint :content_id, index: { unique: false }

      # These aren't authoritative - the only value we realistically care about for logic should be the Lodestone ID.
      # However, querying the Lodestone is a bit expensive, so we'd rather store it locally for reference and update it
      # every now and then. *No uniqueness checks should be applied to this data!*
      t.string :character_name
      t.string :home_datacenter
      t.string :home_world
      t.string :avatar_url
      t.timestamp :last_lodestone_update

      # Instead of just using a boolean, we can just use a nullable field to track when a character was verified.
      t.timestamp :verified_at

      t.timestamps

      t.index [:lodestone_id, :user_id], unique: true
    end
  end
end
