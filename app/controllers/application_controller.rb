class ApplicationController < ActionController::Base
  before_action :require_login

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

    @work_status = Rails.cache.read("work_status") || { status: :unknown, label: nil }
  end

  def ongoing_meetings
    return @ongoing_meetings if defined?(@ongoing_meetings)

    @ongoing_meetings = Rails.cache.read("ongoing_meetings") || []
  end

  private

  def require_login
    return if session[:authenticated]

    session[:return_to] = request.fullpath if request.get?
    redirect_to login_path
  end

  def auto_work_mode
    cached = Rails.cache.read("auto_work_mode")
    return cached unless cached.nil?

    # Cache miss: return false, background job will populate cache
    false
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

    ids = @work_dossier_ids ||= Dossier.work.pluck(:id)
    scope.where.not(dossier_id: ids).or(scope.where(dossier_id: nil))
  end
end
