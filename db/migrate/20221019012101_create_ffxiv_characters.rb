class CreateFFXIVCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :ffxiv_characters, id: :uuid do |t|
      t.number lodestone_id, null: false, index: { unique: true }
      t.string character_name, null: false
      
      t.foreign_key :ffxiv_worlds, column: :home_world_id, primary_key: :exd_id

      t.string :avatar_url

      t.timestamps
    end
  end
end
