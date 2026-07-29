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
      }.to have_enqueued_job(RefreshExternalDataJob).at_least(:once)

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

    it "renders without fetching calendar events synchronously when the cache is cold" do
      create(:google_calendar, enabled: true)

      Rails.cache.clear
      allow(GoogleCalendarService).to receive(:new).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(GoogleCalendarService).not_to have_received(:new)
    end

    it "enqueues a background refresh when the calendar events cache is cold" do
      create(:google_calendar, enabled: true)
      Rails.cache.clear

      expect {
        get today_action_items_path
      }.to have_enqueued_job(RefreshExternalDataJob).at_least(:once)

      expect(response).to have_http_status(:success)
    end

    it "uses cached calendar events when they are present" do
      create(:google_calendar, enabled: true)
      Rails.cache.clear
      Rails.cache.write("calendar_events_#{Date.current}", [])
      allow(GoogleCalendarService).to receive(:new).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(GoogleCalendarService).not_to have_received(:new)
    end
  end
end
