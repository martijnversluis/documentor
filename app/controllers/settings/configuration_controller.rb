module Settings
  class ConfigurationController < ApplicationController
    def index
      # Touch settings to ensure they exist in DB
      @google_client_id = AppSetting["google_client_id"]
      @google_client_secret = AppSetting["google_client_secret"]
      @github_client_id = AppSetting["github_client_id"]
      @github_client_secret = AppSetting["github_client_secret"]
    end

    def update
      AppSetting["google_client_id"] = params[:google_client_id]
      AppSetting["google_client_secret"] = params[:google_client_secret]
      AppSetting["github_client_id"] = params[:github_client_id]
      AppSetting["github_client_secret"] = params[:github_client_secret]

      redirect_to settings_configuration_index_path, notice: "Instellingen opgeslagen"
    end
  end
end
