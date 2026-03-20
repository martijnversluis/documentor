class GithubController < ApplicationController
  def promote
    action_item = ActionItem.create!(
      description: params[:description],
      due_date: Date.current,
      position: 0,
      notes: params[:url]
    )

    matching_dossier = InboxRule.find_matching_dossier(action_item.description)
    action_item.update!(dossier: matching_dossier) if matching_dossier

    GithubHiddenItem.upsert({ item_id: params[:item_id], action: "promote" }, unique_by: :item_id) if params[:item_id].present?

    render json: { success: true, action_item_id: action_item.id }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def snooze
    GithubHiddenItem.upsert({ item_id: params[:item_id], action: "snooze" }, unique_by: :item_id)
    render json: { success: true }
  end

  def ignore
    GithubHiddenItem.upsert({ item_id: params[:item_id], action: "ignore" }, unique_by: :item_id)
    render json: { success: true }
  end

  def dashboard
    @github_account = GithubAccount.first

    unless @github_account
      render partial: "github/no_account"
      return
    end

    cache_key = "github_dashboard_#{@github_account.id}"

    if params[:refresh].present?
      Rails.cache.delete(cache_key)
      RefreshExternalDataJob.perform_later
    end

    @data = Rails.cache.read(cache_key)

    if @data.nil?
      render partial: "github/loading"
    elsif @data.is_a?(Hash) && @data[:auth_error]
      render partial: "github/error", locals: { error: @data[:auth_error], show_reconnect: true }
    else
      render partial: "github/dashboard", locals: { data: @data, account: @github_account }
    end
  end
end
