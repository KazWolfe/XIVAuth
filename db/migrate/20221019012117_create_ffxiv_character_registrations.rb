class CreateFFXIVCharacterRegistrations < ActiveRecord::Migration[7.0]
  def up
    create_table :ffxiv_character_registrations, id: :uuid do |t|

      t.references :character, null: false, foreign_key: true, class: 'FFXIV::Character'
      t.string :region, default: 'na', null: false

      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamp :verified_at

      t.timestamps
    end
  end
  
  def down
    drop_table :ffxiv_character_registrations
  end
end
