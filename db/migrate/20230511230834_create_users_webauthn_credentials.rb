class CreateUsersWebauthnCredentials < ActiveRecord::Migration[7.0]
  def change
    create_table :users_webauthn_credentials do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :external_id, null: false, index: { unique: true }
      t.string :public_key, null: false
      t.string :nickname, null: false
      t.integer :sign_count, null: false, default: 0

      t.timestamps

      t.index %i[user_id nickname], unique: true
    end
  end
end
