Recaptcha.configure do |config|
  config.site_key = Rails.application.credentials.dig(:recaptcha, :site_key) || '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI'
  config.secret_key = Rails.application.credentials.dig(:recaptcha, :secret_key) || '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe'
end
