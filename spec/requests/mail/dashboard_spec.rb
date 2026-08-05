require "rails_helper"

describe "Mail#dashboard" do
  describe "GET /mail/dashboard" do
    it "enqueues a background refresh when the cache is cold" do
      create(:google_account, mail_enabled: true)

      expect {
        get mail_dashboard_path
      }.to have_enqueued_job(RefreshExternalDataJob).at_least(:once)

      expect(response).to have_http_status(:success)
    end

    it "does not enqueue a refresh when there is no mail-enabled account" do
      expect {
        get mail_dashboard_path
      }.not_to have_enqueued_job(RefreshExternalDataJob)

      expect(response).to have_http_status(:success)
    end
  end
end
