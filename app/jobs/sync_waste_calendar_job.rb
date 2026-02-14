require "ximmio"

class SyncWasteCalendarJob < ApplicationJob
  queue_as :default

  # Circulus-Berkel company code
  DEFAULT_COMPANY_CODE = "f8e2844a-095e-48f9-9f98-71fceb51d2c3".freeze

  def perform
    post_code = AppSetting["waste_calendar_post_code"]
    house_number = AppSetting["waste_calendar_house_number"]
    company_code = AppSetting["waste_calendar_company_code"].presence || DEFAULT_COMPANY_CODE

    return unless post_code.present? && house_number.present?

    pickups = fetch_pickups(company_code, post_code, house_number)

    if pickups.any?
      import_pickups(pickups)
      Rails.logger.info "Synced #{pickups.size} waste calendar pickups from Ximmio"
    else
      Rails.logger.warn "No waste pickups found from Ximmio"
    end
  end

  def self.sync_from_ics(ics_content)
    pickups = parse_ics(ics_content)
    return 0 if pickups.empty?

    # Clear future pickups and re-import
    WastePickup.where("collection_date >= ?", Date.current).delete_all

    count = 0
    pickups.each do |pickup|
      WastePickup.create!(
        collection_date: pickup[:date],
        waste_type: pickup[:waste_type]
      )
      count += 1
    rescue ActiveRecord::RecordInvalid
      # Skip duplicates
    end

    count
  end

  private

  def fetch_pickups(company_code, post_code, house_number)
    client = Ximmio::Client.new

    address_response = client.get_addresses(
      company_code: company_code,
      post_code: post_code.gsub(/\s+/, ""),
      house_number: house_number
    )

    address = address_response.addresses.first
    return [] if address.nil?

    calendar_response = client.get_calendar(
      unique_address_id: address.unique_id,
      company_code: company_code,
      start_date: Date.today.to_s,
      end_date: 4.weeks.from_now.to_date.to_s
    )

    calendar_response.calendar.map do |date_time, waste_type|
      {
        date: date_time.to_date,
        waste_type: normalize_waste_type(waste_type)
      }
    end.sort_by { |p| p[:date] }
  rescue StandardError => e
    Rails.logger.error "Failed to fetch waste calendar from Ximmio: #{e.message}"
    []
  end

  def normalize_waste_type(type)
    case type.to_s.downcase
    when /rest/, /grijs/
      "REST"
    when /gft/, /groen/, /tuinafval/
      "GFT"
    when /papier/, /blauw/
      "PAPIER"
    when /pmd/, /plastic/, /metaal/, /drankkarton/
      "PMD"
    when /glas/
      "GLAS"
    when /textiel/, /kleding/
      "TEXTIEL"
    else
      type.upcase.gsub(/[^A-Z]/, "")[0..10]
    end
  end

  def import_pickups(pickups)
    # Clear future pickups and re-import
    WastePickup.where("collection_date >= ?", Date.current).delete_all

    pickups.each do |pickup|
      WastePickup.create!(
        collection_date: pickup[:date],
        waste_type: pickup[:waste_type]
      )
    rescue ActiveRecord::RecordInvalid
      # Skip duplicates
    end
  end

  def self.parse_ics(content)
    pickups = []
    current_event = {}

    content.each_line do |line|
      line = line.strip

      case line
      when /^BEGIN:VEVENT/
        current_event = {}
      when /^DTSTART[^:]*:(\d{8})/
        current_event[:date] = Date.parse($1)
      when /^SUMMARY:(.+)/
        current_event[:waste_type] = normalize_waste_type_class($1)
      when /^END:VEVENT/
        if current_event[:date] && current_event[:waste_type] && current_event[:date] >= Date.current
          pickups << current_event
        end
        current_event = {}
      end
    end

    pickups
  end

  def self.normalize_waste_type_class(type)
    case type.to_s.downcase
    when /rest/, /grijs/
      "REST"
    when /gft/, /groen/, /tuinafval/
      "GFT"
    when /papier/, /blauw/
      "PAPIER"
    when /pmd/, /plastic/, /metaal/, /drankkarton/
      "PMD"
    when /glas/
      "GLAS"
    when /textiel/, /kleding/
      "TEXTIEL"
    else
      type.upcase.gsub(/[^A-Z]/, "")[0..10]
    end
  end
end
