class AddLodestoneMaintenance < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :ffxiv_character_refresh_error, "LODESTONE_MAINTENANCE"
  end
end
