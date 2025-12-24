return unless defined?(OpenTelemetry)

OpenTelemetry::SDK.configure do |c|
  c.use_all

  if defined?(Sentry) && defined(Sentry::OpenTelemetry)
    c.add_span_processor(Sentry::OpenTelemetry::SpanProcessor.instance)
  end
end

if defined?(Sentry) && defined(Sentry::OpenTelemetry)
  OpenTelemetry.propagation = Sentry::OpenTelemetry::Propagator.new
end
