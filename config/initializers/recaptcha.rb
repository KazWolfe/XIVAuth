Recaptcha.configure do |config|
  RECAPTCHA_TEST_SITE_KEY = "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI"
  RECAPTCHA_TEST_SECRET_KEY = "6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe"

  config.site_key = Rails.application.credentials.dig(:recaptcha, :site_key) || RECAPTCHA_TEST_SITE_KEY
  config.secret_key = Rails.application.credentials.dig(:recaptcha, :secret_key) || RECAPTCHA_TEST_SECRET_KEY
end
