Rails.application.config.after_initialize do
  # Skip during asset precompile / other build-time Rake tasks — the
  # build container has no reachable Postgres, so the warmer would hang
  # in libpq until each thread's join timeout expires.
  next if ENV["SECRET_KEY_BASE_DUMMY"].present?
  next if defined?(Rake) && Rake.application.top_level_tasks.any? { |t| t.to_s.start_with?("assets:") }

  # Open the primary PG connection now so the first request does not eat
  # the cold-connect latency (~10s) inside its 15s rack-timeout budget.
  DatabaseConnectionWarmer.warm! if Rails.env.production?

  RefreshExternalDataJob.perform_later
rescue StandardError => e
  Rails.logger.warn "Cache warming initializer failed: #{e.message}"
end
