module Settings
  class GoogleCalendarsController < ApplicationController
    before_action :set_google_account
    before_action :set_google_calendar, only: [:update]

    def index
      @calendars = @google_account.google_calendars.order(:name)
    end

    def update
      @google_calendar.update!(google_calendar_params)

      respond_to do |format|
        format.html { redirect_to settings_google_account_google_calendars_path(@google_account) }
        format.turbo_stream
      end
    end

    private

    def set_google_account
      @google_account = GoogleAccount.find(params[:google_account_id])
    end

    def set_google_calendar
      @google_calendar = @google_account.google_calendars.find(params[:id])
    end

    def google_calendar_params
      params.require(:google_calendar).permit(:enabled)
    end
  end
end
