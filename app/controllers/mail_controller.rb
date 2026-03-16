class MailController < ApplicationController
  def dashboard
    @google_account = GoogleAccount.find_by(mail_enabled: true)

    unless @google_account
      render partial: "mail/no_account"
      return
    end

    cache_key = "mail_dashboard_#{@google_account.id}"

    if params[:refresh].present?
      Rails.cache.delete(cache_key)
      RefreshExternalDataJob.perform_later
    end

    @messages = Rails.cache.read(cache_key)

    if @messages.nil?
      render partial: "mail/loading"
    elsif @messages.is_a?(Hash) && @messages[:auth_error]
      render partial: "mail/error", locals: { error: @messages[:auth_error], show_reconnect: true }
    else
      render partial: "mail/dashboard", locals: { messages: @messages, account: @google_account }
    end
  end

  def promote
    action_item = ActionItem.create!(
      description: params[:description],
      due_date: Date.current,
      context: "werk",
      position: 0,
      notes: params[:notes]
    )

    render json: { success: true, action_item_id: action_item.id }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def dismiss
    google_account = GoogleAccount.find_by(mail_enabled: true)

    unless google_account
      render json: { success: false, error: "Geen mail account" }, status: :unprocessable_entity
      return
    end

    service = GmailService.new(google_account)
    service.dismiss(params[:message_id])

    # Clear cache so the message disappears
    Rails.cache.delete("mail_dashboard_#{google_account.id}")

    render json: { success: true }
  rescue StandardError => e
    Rails.logger.error "Failed to dismiss mail: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
end
