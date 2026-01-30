class GithubController < ApplicationController
  def dashboard
    @github_account = GithubAccount.first

    unless @github_account
      render partial: "github/no_account"
      return
    end

    cache_key = "github_dashboard_#{@github_account.id}"

    # Clear cache if refresh requested
    Rails.cache.delete(cache_key) if params[:refresh].present?

    # Cache for 5 minutes
    @data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      service = GithubService.new(@github_account)
      service.dashboard_data
    rescue GithubService::AuthorizationError => e
      { error: e.message }
    rescue StandardError => e
      Rails.logger.error "GitHub dashboard error: #{e.message}"
      { error: "Kon GitHub data niet ophalen" }
    end

    if @data[:error]
      render partial: "github/error", locals: { error: @data[:error] }
    else
      render partial: "github/dashboard", locals: { data: @data, account: @github_account }
    end
  end
end
