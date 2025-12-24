Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = %i[active_support_logger sentry_logger http_logger]
  config.environment = (ENV["APP_ENV"] || Rails.env.to_s).downcase

  # determine release based on location
  if ENV["RAILWAY_SERVICE_ID"].present? && ENV["RAILWAY_GIT_COMMIT_SHA"].present?
    config.release = "git-#{ENV["RAILWAY_GIT_COMMIT_SHA"][..8]}+railway"
  end

  # set the instrumenter to use OpenTelemetry instead of Sentry
  # config.instrumenter = :otel if defined?(OpenTelemetry) && defined?(Sentry::OpenTelemetry)
  
  config.traces_sample_rate = 0.1
  config.profiles_sample_rate = 0.1

  config.enabled_patches += [:sidekiq_cron]

  config.enable_logs = true
end

SemanticLogger.add_appender(appender: :sentry_ruby)
