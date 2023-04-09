class CreateFFXIVCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :ffxiv_characters, id: :uuid do |t|
      t.integer :lodestone_id, null: false, index: { unique: true }
      t.string :content_id, null: true, index: { unique: true, where: "(content_id IS NOT NULL) OR (content_id != '')" }

      t.string :name, null: false

      # These should probably be normalized to an actual model at some point, but this seems excessive for now. Maybe
      # when it makes sense to add "search for your character" rather than just plain URL additions.
      # ToDo: Let Future Kaz deal with this problem, he sucks and deserves it.
      t.string :home_world, null: false
      t.string :data_center, null: false

      t.string :avatar_url, null: false
      t.string :portrait_url, null: false

      t.timestamps
    end
  end
end
