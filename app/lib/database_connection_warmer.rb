# Eagerly opens every PG connection in the pool at boot so the first
# request on any puma thread does not pay the cold-connect penalty
# (~10s on this host) inside its 15s rack-timeout budget.
#
# Warming only ActiveRecord::Base.connection warms a single slot; puma
# hands later requests to sibling threads which each check out their
# own connection — and the cold-connect happens *outside* AR query
# instrumentation, so the layout render silently blocks for 10s and
# blows the timeout.
module DatabaseConnectionWarmer
  JOIN_TIMEOUT = 30

  def self.warm!
    pool = ActiveRecord::Base.connection_pool
    threads = Array.new(pool.size) do
      Thread.new do
        pool.with_connection { |c| c.execute("SELECT 1") }
        true
      rescue StandardError => e
        Rails.logger.warn "DatabaseConnectionWarmer thread failed: #{e.class}: #{e.message}"
        false
      end
    end
    threads.all? { |t| t.join(JOIN_TIMEOUT) && t.value }
  rescue StandardError => e
    Rails.logger.warn "DatabaseConnectionWarmer failed: #{e.class}: #{e.message}"
    false
  end
end
