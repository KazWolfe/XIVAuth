class AllowNullPasswords < ActiveRecord::Migration[7.1]
  def change
    # Allows null passwords for the purposes of OAuth login
    change_column_null :users, :encrypted_password, true
    change_column_default(:users, :encrypted_password, from: "", to: nil)
  end
end
