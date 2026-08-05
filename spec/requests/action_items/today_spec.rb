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

    it "renders without computing pending reviews synchronously when the cache is cold" do
      Rails.cache.clear
      allow(Review).to receive(:pending_dashboard_data).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(Review).not_to have_received(:pending_dashboard_data)
    end

    it "uses cached pending reviews when they are present" do
      Rails.cache.clear
      key = "pending_reviews/v3/#{Date.current}/#{Time.current.hour}/0"
      Rails.cache.write(key, [])
      allow(Review).to receive(:pending_dashboard_data).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(Review).not_to have_received(:pending_dashboard_data)
    end

    it "renders without computing habits synchronously when the cache is cold" do
      Rails.cache.clear
      allow(Habit).to receive(:today_dashboard_data).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(Habit).not_to have_received(:today_dashboard_data)
    end

    it "uses cached habits when they are present" do
      Rails.cache.clear
      key = "habits_for_today/v1/#{Date.current}/0"
      Rails.cache.write(key, [])
      allow(Habit).to receive(:today_dashboard_data).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(Habit).not_to have_received(:today_dashboard_data)
    end

    it "shows a habits loading state when the cache is cold and habits exist" do
      create(:habit, active: true)

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Gewoontes worden geladen")
    end

    it "hides the habits block entirely when there are no active habits" do
      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Gewoontes worden geladen")
      expect(response.body).not_to include('id="habit_')
    end

    it "renders without loading meetings synchronously when the meetings cache is cold" do
      Rails.cache.clear
      Rails.cache.write("calendar_events_#{Date.current}", [
        { event_id: "abc123", start_time: Time.current, end_time: Time.current + 1.hour, title: "test" }
      ])
      allow(Meeting).to receive(:dashboard_by_event_id).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(Meeting).not_to have_received(:dashboard_by_event_id)
    end

    it "uses cached meetings when they are present" do
      Rails.cache.clear
      Rails.cache.write("calendar_events_#{Date.current}", [
        { event_id: "abc123", start_time: Time.current, end_time: Time.current + 1.hour, title: "test" }
      ])
      Rails.cache.write("meetings_by_event_id/v1", {})
      allow(Meeting).to receive(:dashboard_by_event_id).and_call_original

      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(Meeting).not_to have_received(:dashboard_by_event_id)
    end

    it "enqueues at most one refresh job per request even when several caches are cold" do
      Rails.cache.clear

      expect {
        get today_action_items_path
      }.to have_enqueued_job(RefreshExternalDataJob).exactly(:once)

      expect(response).to have_http_status(:success)
    end

    it "does not fire per-item children queries when rendering items with sub-items" do
      3.times do
        parent = create(:action_item, due_date: Date.current)
        create(:action_item, parent: parent, due_date: Date.current)
        create(:action_item, parent: parent, due_date: Date.current, completed_at: 1.hour.ago)
      end

      # Warm caches so we exercise the render path, not the cache-miss shortcuts
      Rails.cache.write("meetings_by_event_id/v1", {})
      Rails.cache.write("calendar_events_#{Date.current}", [])

      # Prime the request once so route/controller class caches don't skew the count
      get today_action_items_path

      queries = []
      callback = ->(*, payload) do
        next if payload[:name] == "SCHEMA"
        next if payload[:sql].match?(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get today_action_items_path
      end

      children_scope_queries = queries.grep(/FROM "action_items".*"parent_id" =/)
      expect(children_scope_queries).to be_empty,
        "expected no per-item children scope queries, got:\n#{children_scope_queries.join("\n")}"
    end
  end
end
