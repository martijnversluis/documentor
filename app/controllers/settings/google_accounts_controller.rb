module Settings
  class GoogleAccountsController < ApplicationController
    before_action :set_google_account, only: [:destroy]

    def index
      @google_accounts = GoogleAccount.includes(:google_calendars).order(:email)
    end

    def create
      # Start OAuth flow - redirect to Google
      redirect_uri = callback_settings_google_accounts_url
      authorization_url = GoogleCalendarService.authorization_url(redirect_uri)
      redirect_to authorization_url, allow_other_host: true
    end

    def callback
      code = params[:code]

      if code.blank?
        redirect_to settings_google_accounts_path, alert: "Autorisatie geannuleerd"
        return
      end

      begin
        redirect_uri = callback_settings_google_accounts_url
        tokens = GoogleCalendarService.exchange_code(code, redirect_uri)
        user_info = GoogleCalendarService.user_info(tokens[:access_token])

        Rails.logger.info "OAuth tokens received: access_token=#{tokens[:access_token].present?}, refresh_token=#{tokens[:refresh_token].present?}"
        Rails.logger.info "User info: #{user_info.inspect}"

        # Find or create the account
        account = GoogleAccount.find_or_initialize_by(email: user_info[:email])
        account.assign_attributes(
          name: user_info[:name],
          access_token: tokens[:access_token],
          refresh_token: tokens[:refresh_token],
          token_expires_at: tokens[:expires_at]
        )
        account.save!

        # Sync calendars
        sync_calendars(account)

        redirect_to settings_google_accounts_path, notice: "Google account #{account.email} gekoppeld"
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "OAuth callback validation error: #{e.record.errors.full_messages.join(', ')}"
        redirect_to settings_google_accounts_path, alert: "Kon account niet koppelen: #{e.record.errors.full_messages.join(', ')}"
      rescue StandardError => e
        Rails.logger.error "OAuth callback error: #{e.class} - #{e.message}"
        redirect_to settings_google_accounts_path, alert: "Kon account niet koppelen: #{e.message}"
      end
    end

    def destroy
      email = @google_account.email
      @google_account.destroy!
      redirect_to settings_google_accounts_path, notice: "Account #{email} ontkoppeld"
    end

    private

    def set_google_account
      @google_account = GoogleAccount.find(params[:id])
    end

    def sync_calendars(account)
      service = GoogleCalendarService.new(account)
      calendars = service.calendars

      calendars.each do |cal|
        calendar = account.google_calendars.find_or_initialize_by(calendar_id: cal[:id])
        calendar.update!(
          name: cal[:name],
          color: cal[:color],
          enabled: cal[:primary] # Enable primary calendar by default
        )
      end

      # Remove calendars that no longer exist
      existing_ids = calendars.map { |c| c[:id] }
      account.google_calendars.where.not(calendar_id: existing_ids).destroy_all
    end
  end
end
