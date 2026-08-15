# Eagerly opens the primary PG connection at boot so the first request
# does not pay the cold-connect penalty (~10s on this host) inside its
# 15s rack-timeout budget.
module DatabaseConnectionWarmer
  def self.warm!
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError => e
    Rails.logger.warn "DatabaseConnectionWarmer failed: #{e.class}: #{e.message}"
    false
  end
end
