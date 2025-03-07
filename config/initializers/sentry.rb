Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [:active_support_logger, :sentry_logger, :http_logger]
  config.environment = (ENV["APP_ENV"] || Rails.env.to_s).downcase

  # set the instrumenter to use OpenTelemetry instead of Sentry
  config.instrumenter = :otel if defined?(OpenTelemetry) && defined?(Sentry::OpenTelemetry)

  config.enable_tracing = true
  config.traces_sample_rate = 1.0
  config.profiles_sample_rate = 1.0

  config.enabled_patches += [:sidekiq_cron]
end
