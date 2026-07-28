require "rails_helper"

describe "ActionItems#today" do
  around { |ex| Bullet.enable = false; ex.run; Bullet.enable = true }

  describe "GET /action_items/today" do
    it "renders without running the expensive filter counts query when the cache is cold" do
      create(:action_item, due_date: Date.current)

      Rails.cache.clear
      allow(ActionItem).to receive(:filter_counts).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(ActionItem).not_to have_received(:filter_counts)
    end

    it "enqueues a background refresh when the filter counts cache is cold" do
      Rails.cache.clear

      expect {
        get today_action_items_path
      }.to have_enqueued_job(RefreshExternalDataJob)

      expect(response).to have_http_status(:success)
    end

    it "uses the cached counts when they are present" do
      cached = ActionItem::FILTER_COUNT_KEYS.index_with { 7 }
      Rails.cache.clear
      Rails.cache.write("work_dossier_ids/v1", [])
      Rails.cache.write("action_items/filter_counts/v1/#{Date.current}/personal:", cached)

      allow(ActionItem).to receive(:filter_counts).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(ActionItem).not_to have_received(:filter_counts)
    end
  end
end
