Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow Hey.com (where content script runs) and localhost for development
    origins "https://app.hey.com", "http://localhost:3000", "http://127.0.0.1:3000"

    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :patch, :delete, :options],
      credentials: false
  end
end
