class ChargingStatusService
  HOMY_URL = "http://homy.test/api/charging_status".freeze

  def fetch_status
    response = connection.get

    return nil unless response.success?

    data = JSON.parse(response.body)
    {
      needs_charging: data["needs_charging"],
      battery_range_km: data["battery_range_km"],
      trip_distance_km: data["trip_distance_km"],
      available_range_km: data["available_range_km"],
      last_checked: data["last_checked"]
    }
  rescue StandardError => e
    Rails.logger.error "ChargingStatusService error: #{e.message}"
    nil
  end

  def needs_charging?
    status = fetch_status
    status&.dig(:needs_charging) == true
  end

  private

  def connection
    @connection ||= Faraday.new(url: HOMY_URL) do |f|
      f.request :retry
    end
  end
end
