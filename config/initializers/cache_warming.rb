Rails.application.config.after_initialize do
  RefreshExternalDataJob.perform_later
rescue StandardError => e
  Rails.logger.warn "Cache warming job enqueue failed: #{e.message}"
end
