module Settings
  class WasteCalendarController < ApplicationController
    def index
      @post_code = AppSetting["waste_calendar_post_code"]
      @house_number = AppSetting["waste_calendar_house_number"]
      @pickups = WastePickup.upcoming.limit(20)
    end

    def update
      AppSetting["waste_calendar_post_code"] = params[:post_code].to_s.strip.upcase
      AppSetting["waste_calendar_house_number"] = params[:house_number].to_s.strip

      redirect_to settings_waste_calendar_index_path, notice: "Afvalinstellingen opgeslagen"
    end

    def sync
      SyncWasteCalendarJob.perform_now
      count = WastePickup.upcoming.count

      if count > 0
        redirect_to settings_waste_calendar_index_path, notice: "#{count} ophaaldata gesynchroniseerd"
      else
        redirect_to settings_waste_calendar_index_path, alert: "Geen ophaaldata gevonden. Voeg ze handmatig toe of upload een ICS bestand."
      end
    rescue StandardError => e
      redirect_to settings_waste_calendar_index_path, alert: "Synchronisatie mislukt: #{e.message}"
    end

    def create_pickup
      WastePickup.create!(
        collection_date: Date.parse(params[:collection_date]),
        waste_type: params[:waste_type].to_s.upcase
      )
      redirect_to settings_waste_calendar_index_path, notice: "Ophaaldatum toegevoegd"
    rescue Date::Error
      redirect_to settings_waste_calendar_index_path, alert: "Ongeldige datum"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to settings_waste_calendar_index_path, alert: e.message
    end

    def destroy_pickup
      WastePickup.find(params[:id]).destroy
      redirect_to settings_waste_calendar_index_path, notice: "Ophaaldatum verwijderd"
    end

    def import_ics
      unless params[:ics_file].present?
        redirect_to settings_waste_calendar_index_path, alert: "Selecteer een ICS bestand"
        return
      end

      content = params[:ics_file].read
      count = SyncWasteCalendarJob.sync_from_ics(content)

      if count > 0
        redirect_to settings_waste_calendar_index_path, notice: "#{count} ophaaldata geïmporteerd"
      else
        redirect_to settings_waste_calendar_index_path, alert: "Geen geldige ophaaldata gevonden in bestand"
      end
    rescue StandardError => e
      redirect_to settings_waste_calendar_index_path, alert: "Import mislukt: #{e.message}"
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
