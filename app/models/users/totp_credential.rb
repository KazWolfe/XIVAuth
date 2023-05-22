class Users::TotpCredential < ApplicationRecord
  belongs_to :user

  devise :two_factor_authenticatable,
         :two_factor_backupable, otp_backup_code_length: 16, otp_number_of_backup_codes: 5

  def validate_and_consume_otp_or_backup!(code)
    return true if validate_and_consume_otp!(code)
    return true if invalidate_otp_backup_code!(code)

    false
  end

  def otp_provisioning_uri
    issuer = "XIVAuth"
    super("[#{issuer}] #{user.email}", issuer: issuer)
  end
end
