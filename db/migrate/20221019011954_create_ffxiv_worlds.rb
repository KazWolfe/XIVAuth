class CreateFFXIVWorlds < ActiveRecord::Migration[7.0]
  def up
    create_table :ffxiv_datacenters do |t|
      t.number exd_id, null: false, index: { unique: true }
      t.string name,   null: false, index: { unique: true }
      t.number region, null: false
    end

    create_table :ffxiv_worlds do |t|
      t.number exd_id,      null: false, index: { unique: true }
      t.string name,        null: false, index: { unique: true }

      t.foreign_key :ffxiv_datacenters, column: :datacenter_id, primary_key: :exd_id

      t.boolean public, null: false, default: false

      t.timestamps
    end
  end

  def down
    drop_table :ffxiv_worlds
    drop_table :ffxiv_datacenters
  end
end
