class HeyController < ApplicationController
  def dashboard
    @account = ImapAccount.enabled.first

    unless @account
      render partial: "hey/no_account"
      return
    end

    cache_key = "hey_dashboard_#{@account.id}"

    if params[:refresh].present?
      Rails.cache.delete(cache_key)
      RefreshExternalDataJob.perform_later
    end

    @messages = Rails.cache.read(cache_key)

    if @messages.nil?
      enqueue_cache_refresh
      render partial: "hey/loading"
    elsif @messages.is_a?(Hash) && @messages[:auth_error]
      render partial: "hey/error", locals: { error: @messages[:auth_error] }
    else
      render partial: "hey/dashboard", locals: { messages: @messages, account: @account }
    end
  end

  def mark_as_read
    account = ImapAccount.enabled.first
    @uid = params[:uid].to_s

    unless account && @uid.present?
      head :unprocessable_entity
      return
    end

    ImapMailService.new(account).mark_as_read(@uid)
    Rails.cache.delete("hey_dashboard_#{account.id}")

    respond_to do |format|
      format.turbo_stream
      format.json { render json: { success: true } }
    end
  rescue StandardError => e
    Rails.logger.warn "HEY mark_as_read failed: #{e.class}: #{e.message}"
    respond_to do |format|
      format.turbo_stream { head :unprocessable_entity }
      format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
    end
  end
end
