class WasteCalendarService
  HOMY_URL = "http://homy.test/api/waste_calendar".freeze

  def initialize(post_code: nil, house_number: nil)
    @post_code = post_code || AppSetting["waste_calendar_post_code"]
    @house_number = house_number || AppSetting["waste_calendar_house_number"]
  end

  def fetch_pickups
    return [] unless configured?

    response = connection.get do |req|
      req.params["post_code"] = @post_code
      req.params["house_number"] = @house_number
    end

    return [] unless response.success?

    data = JSON.parse(response.body)
    data["pickups"].map do |pickup|
      {
        date: Date.parse(pickup["date"]),
        waste_type: pickup["waste_type"]
      }
    end
  rescue StandardError => e
    Rails.logger.error "WasteCalendarService error: #{e.message}"
    []
  end

  def tomorrows_pickups
    fetch_pickups.select { |p| p[:date] == Date.tomorrow }
  end

  def configured?
    @post_code.present? && @house_number.present?
  end

  private

  def connection
    @connection ||= Faraday.new(url: HOMY_URL) do |f|
      f.request :retry
    end
  end
end
