class WebauthnLastUsed < ActiveRecord::Migration[8.0]
  def change
    add_column :user_webauthn_credentials, :last_used_at, :datetime, null: true
  end
end
