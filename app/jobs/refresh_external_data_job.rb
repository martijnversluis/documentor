class RefreshExternalDataJob < ApplicationJob
  CACHE_TTL = 10.minutes

  def perform
    refresh_work_mode
    refresh_work_status
    refresh_ongoing_meetings
    refresh_github_dashboards
    refresh_mail_dashboards
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

  def refresh_github_dashboards
    GithubAccount.find_each do |account|
      data = GithubService.new(account).dashboard_data
      Rails.cache.write("github_dashboard_#{account.id}", data, expires_in: CACHE_TTL)
    rescue StandardError => e
      Rails.logger.warn "RefreshExternalDataJob: GitHub dashboard failed for account #{account.id}: #{e.message}"
    end
  end

  def refresh_mail_dashboards
    GoogleAccount.where(mail_enabled: true).find_each do |account|
      messages = GmailService.new(account).unread_messages
      Rails.cache.write("mail_dashboard_#{account.id}", messages, expires_in: CACHE_TTL)
    rescue StandardError => e
      Rails.logger.warn "RefreshExternalDataJob: Mail dashboard failed for account #{account.id}: #{e.message}"
    end
  end
end
