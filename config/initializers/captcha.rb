RailsCloudflareTurnstile.configure do |c|
  TURNSTILE_TEST_SITE_KEY = "3x00000000000000000000FF"
  TURNSTILE_TEST_SECRET_KEY = "1x0000000000000000000000000000000AA"

  c.site_key = Rails.application.credentials.dig(:turnstile, :site_key) || TURNSTILE_TEST_SITE_KEY
  c.secret_key = Rails.application.credentials.dig(:turnstile, :secret_key) || TURNSTILE_TEST_SECRET_KEY

  c.mock_enabled = false

  c.fail_open = Rails.env.development?
end
