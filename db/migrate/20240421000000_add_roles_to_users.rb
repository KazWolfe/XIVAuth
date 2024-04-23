class AddRolesToUsers < ActiveRecord::Migration[7.1]
  def change
    create_enum :user_roles, %w[developer admin]
    add_column :users, :roles, :enum, enum_type: :user_roles, array: true, null: false, default: []
  end
end
