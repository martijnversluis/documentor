module Settings
  class GithubAccountsController < ApplicationController
    def index
      @github_accounts = GithubAccount.all
    end

    def create
      redirect_uri = callback_settings_github_accounts_url
      authorization_url = GithubService.authorization_url(redirect_uri)
      redirect_to authorization_url, allow_other_host: true
    end

    def callback
      if params[:error]
        redirect_to settings_github_accounts_path, alert: "GitHub autorisatie geweigerd: #{params[:error_description]}"
        return
      end

      redirect_uri = callback_settings_github_accounts_url
      access_token = GithubService.exchange_code(params[:code], redirect_uri)
      user_info = GithubService.user_info(access_token)

      github_account = GithubAccount.find_or_initialize_by(username: user_info[:login])
      github_account.access_token = access_token
      github_account.save!

      redirect_to settings_github_accounts_path, notice: "GitHub account #{user_info[:login]} gekoppeld!"
    rescue GithubService::AuthorizationError => e
      redirect_to settings_github_accounts_path, alert: "Kon account niet koppelen: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "GitHub OAuth error: #{e.message}"
      redirect_to settings_github_accounts_path, alert: "Kon account niet koppelen: #{e.message}"
    end

    def destroy
      @github_account = GithubAccount.find(params[:id])
      @github_account.destroy
      redirect_to settings_github_accounts_path, notice: "GitHub account ontkoppeld"
    end
  end
end
