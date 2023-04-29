class CreateUsersTOTPCredentials < ActiveRecord::Migration[7.0]
  def change
    create_table :users_totp_credentials, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      
      t.string :otp_secret, null: false
      t.integer :consumed_timestep, null: true
      t.string :otp_backup_codes, null: true, array: true
      
      t.timestamps
    end
  end
end
