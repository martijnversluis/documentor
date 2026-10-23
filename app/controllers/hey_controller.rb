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
end
