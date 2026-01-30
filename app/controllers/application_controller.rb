class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :work_mode?, :work_mode_auto?, :work_status, :ongoing_meetings

  def work_mode?
    # If user manually toggled within the last hour, respect their choice
    if cookies[:work_mode_manual].present?
      return cookies[:work_mode] == "true"
    end

    # Otherwise, auto-determine from calendar (with caching)
    auto_work_mode
  end

  def work_mode_auto?
    GoogleAccount.joins(:google_calendars).where(google_calendars: { enabled: true }).exists?
  end

  def work_status
    return @work_status if defined?(@work_status)

    @work_status = Rails.cache.fetch("work_status", expires_in: 5.minutes) do
      if work_mode_auto?
        GoogleCalendarService.work_status
      else
        { status: :unknown, label: nil }
      end
    rescue StandardError => e
      Rails.logger.warn "Work status check failed: #{e.message}"
      { status: :unknown, label: nil }
    end
  end

  def ongoing_meetings
    return @ongoing_meetings if defined?(@ongoing_meetings)

    @ongoing_meetings = Rails.cache.fetch("ongoing_meetings", expires_in: 1.minute) do
      GoogleCalendarService.ongoing_meetings
    rescue StandardError => e
      Rails.logger.warn "Ongoing meetings check failed: #{e.message}"
      []
    end
  end

  private

  def auto_work_mode
    # Cache the result for 5 minutes to avoid constant API calls
    cache_key = "auto_work_mode"
    cached = Rails.cache.read(cache_key)
    return cached unless cached.nil?

    result = begin
      GoogleCalendarService.should_be_working?
    rescue StandardError => e
      Rails.logger.warn "Auto work mode check failed: #{e.message}"
      false
    end

    Rails.cache.write(cache_key, result, expires_in: 5.minutes)
    result
  end

  # Filter dossiers based on work mode
  def filtered_dossiers(scope = Dossier.active)
    # Work mode: show all, personal mode: hide work dossiers
    work_mode? ? scope : scope.personal
  end

  # Filter action items based on work mode
  def filtered_action_items(scope = ActionItem.all)
    # Work mode: show all, personal mode: hide work dossier items
    return scope if work_mode?

    work_dossier_ids = Dossier.work.pluck(:id)
    scope.where.not(dossier_id: work_dossier_ids).or(scope.where(dossier_id: nil))
  end
end
