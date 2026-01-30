class WorkModeController < ApplicationController
  def toggle
    # Determine new state (toggle current effective state)
    new_state = !work_mode?

    if new_state
      cookies[:work_mode] = { value: "true", expires: 1.year.from_now }
    else
      cookies.delete(:work_mode)
    end

    # Mark as manual override (expires after 1 hour, then auto-mode takes over again)
    cookies[:work_mode_manual] = { value: "true", expires: 1.hour.from_now }

    # Clear the caches so they recalculate next time
    Rails.cache.delete("auto_work_mode")
    Rails.cache.delete("work_status")

    redirect_back fallback_location: root_path
  end
end
