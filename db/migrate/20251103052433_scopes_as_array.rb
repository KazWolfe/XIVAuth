class ScopesAsArray < ActiveRecord::Migration[8.1]
  def up
    change_column :oauth_access_tokens, :scopes, :string, array: true, null: true,
                  using: "(string_to_array(scopes, ' '))"

    change_column :oauth_access_grants, :scopes, :string, array: true, null: true,
                  using: "(string_to_array(scopes, ' '))"

    change_column :oauth_device_grants, :scopes, :string, array: true, null: true,
                  using: "(string_to_array(scopes, ' '))"

    change_column :client_application_oauth_clients, :scopes, :string, array: true, null: true,
                  using: "(string_to_array(scopes, ' '))"
  end

  def down
    change_column :oauth_access_tokens, :scopes, :string, array: false, null: true,
                  using: "(array_to_string(scopes, ' '))"

    change_column :oauth_access_grants, :scopes, :string, array: false, null: true,
                  using: "(array_to_string(scopes, ' '))"

    change_column :oauth_device_grants, :scopes, :string, array: false, null: true,
                  using: "(array_to_string(scopes, ' '))"

    change_column :client_application_oauth_clients, :scopes, :string, array: false, null: true,
                  using: "(array_to_string(scopes, ' '))"
  end
end
