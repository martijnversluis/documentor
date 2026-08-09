class ApplicationController < ActionController::Base
  # Process-local memo for cache reads that fire on every request. Fronts SolidCache
  # so a single slow/failed lookup on the shared PG database can't stall the request
  # thread. TTL is short enough that background writes still propagate quickly.
  PROCESS_CACHE = ActiveSupport::Cache::MemoryStore.new(size: 64.kilobytes)
  HOT_CACHE_TTL = 10.seconds

  before_action :require_login

  helper_method :work_mode?, :work_mode_auto?, :work_status, :ongoing_meetings, :enqueue_cache_refresh

  def enqueue_cache_refresh
    return if @cache_refresh_enqueued
    @cache_refresh_enqueued = true
    RefreshExternalDataJob.perform_later
  end

  def work_mode?
    return @work_mode if defined?(@work_mode)

    @work_mode = if cookies[:work_mode_manual].present?
                   cookies[:work_mode] == "true"
                 else
                   auto_work_mode
                 end
  end

  def work_mode_auto?
    return @work_mode_auto if defined?(@work_mode_auto)

    @work_mode_auto = hot_cache_fetch("work_mode_auto", default: false)
  end

  def work_status
    @work_status ||= hot_cache_fetch("work_status", default: { status: :unknown, label: nil })
  end

  def ongoing_meetings
    @ongoing_meetings ||= hot_cache_fetch("ongoing_meetings", default: [])
  end

  private

  def require_login
    return if session[:authenticated]

    session[:return_to] = request.fullpath if request.get?
    redirect_to login_path
  end

  def auto_work_mode
    hot_cache_fetch("auto_work_mode", default: false)
  end

  # Fetches key from SolidCache at most once per HOT_CACHE_TTL per process, and
  # swallows any error (statement timeout, connection error, rack-timeout), falling
  # back to +default+. Any of these values is fine to be a few seconds stale.
  def hot_cache_fetch(key, default:)
    PROCESS_CACHE.fetch(key, expires_in: HOT_CACHE_TTL) { safe_cache_read(key) } || default
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

    ids = work_dossier_ids
    scope.where.not(dossier_id: ids).or(scope.where(dossier_id: nil))
  end

  def work_dossier_ids
    @work_dossier_ids ||= work_dossier_ids_lookup
  end

  def work_dossier_ids_lookup
    Rails.cache.fetch("work_dossier_ids/v1", expires_in: 5.minutes) do
      Dossier.work.pluck(:id)
    end
  rescue StandardError, Rack::Timeout::RequestTimeoutException => e
    Rails.logger.warn("work_dossier_ids fell back to direct query: #{e.class}: #{e.message}")
    Dossier.work.pluck(:id)
  end

  # Reads +key+ from Rails.cache but never blocks the request thread on failure.
  # Explicitly catches +Rack::Timeout::RequestTimeoutException+ (which inherits
  # from +Exception+, not +StandardError+, so it slips past broad rescues) so a
  # cache read that hits the rack-timeout deadline degrades to a cache miss
  # instead of a 500.
  def safe_cache_read(key)
    Rails.cache.read(key)
  rescue StandardError, Rack::Timeout::RequestTimeoutException => e
    Rails.logger.warn("safe_cache_read(#{key}) failed: #{e.class}: #{e.message}")
    nil
  end
end
