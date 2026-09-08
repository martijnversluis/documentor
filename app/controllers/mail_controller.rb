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
      enqueue_cache_refresh
      render partial: "mail/loading"
    elsif @messages.is_a?(Hash) && @messages[:auth_error]
      render partial: "mail/error", locals: { error: @messages[:auth_error], show_reconnect: true }
    else
      render partial: "mail/dashboard", locals: { messages: @messages, account: @google_account }
    end
  end

  def new_promote
    @thread_id = params[:thread_id]
    @action_item = ActionItem.new(
      description: params[:description],
      notes: params[:notes],
      due_date: Date.current
    )
  end

  def promote
    attrs = action_item_params
    @thread_id = params[:thread_id]
    @action_item = ActionItem.new(attrs)
    @action_item.save!

    if @thread_id.present?
      account = GoogleAccount.find_by(mail_enabled: true)
      if account
        begin
          GmailService.new(account).mark_thread_as_read(@thread_id)
          Rails.cache.delete("mail_dashboard_#{account.id}")
        rescue StandardError => e
          Rails.logger.warn "Mail promote: mark_thread_as_read failed for #{@thread_id}: #{e.class}: #{e.message}"
        end
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.json { render json: { success: true, action_item_id: @action_item.id } }
    end
  rescue ActiveRecord::RecordInvalid => e
    @thread_id = params[:thread_id]
    respond_to do |format|
      format.turbo_stream { render :promote_error, status: :unprocessable_entity }
      format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
    end
  end

  def dismiss
    with_mail_account do |account|
      GmailService.new(account).trash_thread(params[:thread_id])
      Rails.cache.delete("mail_dashboard_#{account.id}")
    end
  end

  def mark_as_read
    with_mail_account do |account|
      GmailService.new(account).mark_thread_as_read(params[:thread_id])
      Rails.cache.delete("mail_dashboard_#{account.id}")
    end
  end

  private

  def action_item_params
    permitted = params.fetch(:action_item, {}).permit(:description, :notes, :dossier_id, :context, :due_date)
    permitted[:description] = params[:description] if permitted[:description].blank? && params[:description].present?
    permitted[:notes] = params[:notes] if permitted[:notes].blank? && params[:notes].present?
    permitted[:due_date] = Date.current if permitted[:due_date].blank?
    permitted
  end

  def with_mail_account
    google_account = GoogleAccount.find_by(mail_enabled: true)

    unless google_account
      render json: { success: false, error: "Geen mail account" }, status: :unprocessable_entity
      return
    end

    yield(google_account)

    render json: { success: true }
  rescue StandardError => e
    Rails.logger.error "Mail action failed: #{e.class}: #{e.message}"
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
end
