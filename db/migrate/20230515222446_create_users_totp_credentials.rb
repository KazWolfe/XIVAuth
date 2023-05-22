class CreateUsersTotpCredentials < ActiveRecord::Migration[7.0]
  def change
    create_table :users_totp_credentials, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }

      t.string :otp_secret, null: false
      t.numeric :consumed_timestep
      t.boolean :otp_enabled, default: false

      t.string :otp_backup_codes, array: true

      t.timestamps
    end
  end
end
