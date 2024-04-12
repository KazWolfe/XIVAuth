class AllowNullPasswords < ActiveRecord::Migration[7.1]
  def change
    # Allows null passwords for the purposes of OAuth login
    change_column_null :users, :encrypted_password, true
  end
end
