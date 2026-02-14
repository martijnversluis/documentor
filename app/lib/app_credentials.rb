# Credentials helper - reads from database (AppSetting, encrypted)
module AppCredentials
  class << self
    def google
      {
        client_id: AppSetting["google_client_id"],
        client_secret: AppSetting["google_client_secret"]
      }
    rescue ActiveRecord::StatementInvalid
      empty_credentials
    end

    def github
      {
        client_id: AppSetting["github_client_id"],
        client_secret: AppSetting["github_client_secret"]
      }
    rescue ActiveRecord::StatementInvalid
      empty_credentials
    end

    def configured?(service)
      creds = send(service)
      creds[:client_id].present? && creds[:client_secret].present?
    end

    private

    def empty_credentials
      { client_id: nil, client_secret: nil }
    end
  end
end
