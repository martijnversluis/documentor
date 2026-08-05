require "rails_helper"

describe "Github#dashboard" do
  describe "GET /github/dashboard" do
    it "enqueues a background refresh when the cache is cold" do
      GithubAccount.create!(username: "octocat", access_token: "token")

      expect {
        get github_dashboard_path
      }.to have_enqueued_job(RefreshExternalDataJob).at_least(:once)

      expect(response).to have_http_status(:success)
    end

    it "does not enqueue a refresh when there is no github account" do
      expect {
        get github_dashboard_path
      }.not_to have_enqueued_job(RefreshExternalDataJob)

      expect(response).to have_http_status(:success)
    end
  end
end
