Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # Allow API responses to ignore CORS
  allow do
    origins '*'
    resource '/api/*',
             credentials: false,
             headers: :any,
             methods: :any
  end

  # Slightly more restrictive rules for OAuth
  %w[/oauth/token /oauth/revoke].each do |oauth_path|
    allow do
      origins '*'
      resource oauth_path,
               headers: %w[Authorization X-CSRF-Token],
               credentials: false,
               methods: %i[post options]
    end
  end
end
