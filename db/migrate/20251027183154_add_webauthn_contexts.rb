class AddWebauthnContexts < ActiveRecord::Migration[8.1]
  def change
    add_column :user_webauthn_credentials, :aaguid, :uuid, null: true
    add_column :user_webauthn_credentials, :transports, :string, array: true, null: true
    add_column :user_webauthn_credentials, :resident_key, :boolean, null: false, default: false
    add_column :user_webauthn_credentials, :raw_data, :jsonb, null: true
  end
end
