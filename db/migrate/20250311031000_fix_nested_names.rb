class FixNestedNames < ActiveRecord::Migration[8.0]
  def change
    rename_table :users_profiles, :user_profiles
    rename_table :users_social_identities, :user_social_identities
    rename_table :users_totp_credentials, :user_totp_credentials
    rename_table :users_webauthn_credentials, :user_webauthn_credentials
  end
end
