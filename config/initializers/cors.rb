# Configure allowed origins for CORS (for browser extension API access)
# Set CORS_ORIGINS env var with comma-separated origins, e.g.:
# CORS_ORIGINS=https://app.hey.com,https://mail.google.com

cors_origins = ENV.fetch("CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")
  .split(",")
  .map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*cors_origins)

    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :patch, :delete, :options],
      credentials: false
  end
end
