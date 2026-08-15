Rails.application.config.after_initialize do
  # Open the primary PG connection now so the first request does not eat
  # the cold-connect latency (~10s) inside its 15s rack-timeout budget.
  DatabaseConnectionWarmer.warm! if Rails.env.production?

  RefreshExternalDataJob.perform_later
rescue StandardError => e
  Rails.logger.warn "Cache warming initializer failed: #{e.message}"
end
