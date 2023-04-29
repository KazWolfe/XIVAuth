class Users::TOTPCredential < ApplicationRecord
  devise :two_factor_authenticatable
  devise :two_factor_backupable, otp_backup_code_length: 16, otp_number_of_backup_codes: 10

  belongs_to :user
end
