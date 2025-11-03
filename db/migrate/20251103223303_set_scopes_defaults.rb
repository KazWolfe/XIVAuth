class SetScopesDefaults < ActiveRecord::Migration[8.1]
  def change
    change_column :oauth_access_tokens, :scopes, :string, array: true, null: false, default: []
    change_column :oauth_access_grants, :scopes, :string, array: true, null: false, default: []
    change_column :oauth_device_grants, :scopes, :string, array: true, null: false, default: []
    change_column :client_application_oauth_clients, :scopes, :string, array: true, null: false, default: []
  end
end
