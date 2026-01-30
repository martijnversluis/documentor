module Settings
  class WasteCalendarController < ApplicationController
    def index
      @post_code = AppSetting["waste_calendar_post_code"]
      @house_number = AppSetting["waste_calendar_house_number"]
    end

    def update
      AppSetting["waste_calendar_post_code"] = params[:post_code].to_s.strip.upcase
      AppSetting["waste_calendar_house_number"] = params[:house_number].to_s.strip

      redirect_to settings_waste_calendar_index_path, notice: "Afvalinstellingen opgeslagen"
    end

    def test
      post_code = AppSetting["waste_calendar_post_code"]
      house_number = AppSetting["waste_calendar_house_number"]

      unless post_code.present? && house_number.present?
        redirect_to settings_waste_calendar_index_path, alert: "Vul eerst je adresgegevens in"
        return
      end

      service = WasteCalendarService.new(post_code: post_code, house_number: house_number)
      pickups = service.fetch_pickups

      if pickups.empty?
        redirect_to settings_waste_calendar_index_path, alert: "Geen ophaaldata gevonden voor dit adres"
      else
        redirect_to settings_waste_calendar_index_path, notice: "Verbinding succesvol! #{pickups.count} ophaaldata gevonden."
      end
    rescue StandardError => e
      redirect_to settings_waste_calendar_index_path, alert: "Fout bij ophalen: #{e.message}"
    end
  end
end
