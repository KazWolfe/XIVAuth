class CreateCharacterBans < ActiveRecord::Migration[7.0]
  def change
    create_table :character_bans, id: :uuid do |t|
      t.references :character, polymorphic: true, type: :uuid
      t.string :reason, null: true
      t.datetime :created_at, null: false
    end
  end
end
