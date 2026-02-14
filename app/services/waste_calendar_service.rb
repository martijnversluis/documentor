require "ximmio"

class WasteCalendarService
  DEFAULT_COMPANY_CODE = "f8e2844a-095e-48f9-9f98-71fceb51d2c3".freeze

  def initialize(post_code: nil, house_number: nil)
    @post_code = post_code || AppSetting["waste_calendar_post_code"]
    @house_number = house_number || AppSetting["waste_calendar_house_number"]
    @company_code = AppSetting["waste_calendar_company_code"].presence || DEFAULT_COMPANY_CODE
  end

  def fetch_pickups
    client = Ximmio::Client.new

    address_response = client.get_addresses(
      company_code: @company_code,
      post_code: @post_code.gsub(/\s+/, ""),
      house_number: @house_number
    )

    address = address_response.addresses.first
    return [] if address.nil?

    calendar_response = client.get_calendar(
      unique_address_id: address.unique_id,
      company_code: @company_code,
      start_date: Date.today.to_s,
      end_date: 4.weeks.from_now.to_date.to_s
    )

    calendar_response.calendar.map do |date_time, waste_type|
      {
        date: date_time.to_date,
        waste_type: waste_type
      }
    end.sort_by { |p| p[:date] }
  end

  def tomorrows_pickups
    WastePickup.tomorrow.map do |pickup|
      {
        date: pickup.collection_date,
        waste_type: pickup.waste_type
      }
    end
  end

  def configured?
    @post_code.present? && @house_number.present?
  end

  def sync!
    SyncWasteCalendarJob.perform_now
  end
end
