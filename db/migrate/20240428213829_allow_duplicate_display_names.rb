class AllowDuplicateDisplayNames < ActiveRecord::Migration[7.1]
  def change
    remove_index :users_profiles, name: 'index_users_profiles_on_lower_display_name'
    change_column :users_profiles, :display_name, :string, limit: 64
  end
end
