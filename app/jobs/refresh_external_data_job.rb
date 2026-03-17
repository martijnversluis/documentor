class RefreshExternalDataJob < ApplicationJob
  CACHE_TTL = 10.minutes

  def perform
    refresh_work_mode
    refresh_work_status
    refresh_ongoing_meetings
    refresh_calendar_events
    refresh_github_dashboards
    refresh_mail_dashboards
    sync_calendar_lists
  end

  private

  def refresh_work_mode
    result = GoogleCalendarService.should_be_working?
    Rails.cache.write("auto_work_mode", result, expires_in: CACHE_TTL)
  rescue StandardError => e
    Rails.logger.warn "RefreshExternalDataJob: work mode check failed: #{e.message}"
  end

  def refresh_work_status
    result = GoogleCalendarService.work_status
    Rails.cache.write("work_status", result, expires_in: CACHE_TTL)
  rescue StandardError => e
    Rails.logger.warn "RefreshExternalDataJob: work status check failed: #{e.message}"
  end

  def refresh_ongoing_meetings
    result = GoogleCalendarService.ongoing_meetings
    Rails.cache.write("ongoing_meetings", result, expires_in: CACHE_TTL)
  rescue StandardError => e
    Rails.logger.warn "RefreshExternalDataJob: ongoing meetings check failed: #{e.message}"
  end

  def refresh_calendar_events
    [Date.yesterday, Date.current, Date.tomorrow].each do |date|
      events = fetch_all_calendar_events(date, date)
      Rails.cache.write("calendar_events_#{date}", events, expires_in: CACHE_TTL)
    end
  rescue StandardError => e
    Rails.logger.warn "RefreshExternalDataJob: calendar events failed: #{e.message}"
  end

  def fetch_all_calendar_events(start_date, end_date)
    events = []

    GoogleAccount.includes(:google_calendars).find_each do |account|
      next unless account.enabled_calendars.any?

      service = GoogleCalendarService.new(account)
      events.concat(service.events_for_range(start_date: start_date, end_date: end_date))
    rescue StandardError => e
      Rails.logger.warn "RefreshExternalDataJob: calendar events for #{account.email} failed: #{e.message}"
    end

    events.sort_by { |e| e[:start_time] || start_date.beginning_of_day }
  end

  def refresh_github_dashboards
    GithubAccount.find_each do |account|
      data = GithubService.new(account).dashboard_data
      Rails.cache.write("github_dashboard_#{account.id}", data, expires_in: CACHE_TTL)
    rescue GithubService::AuthorizationError => e
      Rails.logger.warn "RefreshExternalDataJob: GitHub auth failed for account #{account.id}: #{e.message}"
      Rails.cache.write("github_dashboard_#{account.id}", { auth_error: e.message }, expires_in: CACHE_TTL)
    rescue StandardError => e
      Rails.logger.warn "RefreshExternalDataJob: GitHub dashboard failed for account #{account.id}: #{e.message}"
    end
  end

  def sync_calendar_lists
    return if Rails.cache.read("calendar_lists_synced_at").present?

    GoogleAccount.find_each do |account|
      account.sync_calendars!
    rescue StandardError => e
      Rails.logger.warn "RefreshExternalDataJob: calendar sync for #{account.email} failed: #{e.message}"
    end

    Rails.cache.write("calendar_lists_synced_at", Time.current, expires_in: 1.hour)
  rescue StandardError => e
    Rails.logger.warn "RefreshExternalDataJob: calendar list sync failed: #{e.message}"
  end

  def refresh_mail_dashboards
    GoogleAccount.where(mail_enabled: true).find_each do |account|
      messages = GmailService.new(account).unread_messages
      Rails.cache.write("mail_dashboard_#{account.id}", messages, expires_in: CACHE_TTL)
    rescue GmailService::AuthorizationError, GmailService::TokenRefreshError => e
      Rails.logger.warn "RefreshExternalDataJob: Mail auth failed for account #{account.id}: #{e.message}"
      Rails.cache.write("mail_dashboard_#{account.id}", { auth_error: e.message }, expires_in: CACHE_TTL)
    rescue StandardError => e
      Rails.logger.warn "RefreshExternalDataJob: Mail dashboard failed for account #{account.id}: #{e.message}"
    end
  end
end
