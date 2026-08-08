require "rails_helper"

describe "ActionItems#fragment" do
  around { |ex| Bullet.enable = false; ex.run; Bullet.enable = true }

  describe "GET /action_items/fragment/:filter/pending_reviews" do
    it "returns an empty body when there are no pending reviews cached" do
      allow(Rails.cache).to receive(:read).and_call_original
      allow(Rails.cache).to receive(:read).with(a_string_starting_with("pending_reviews/")).and_return(nil)

      get fragment_action_items_path(filter: :today, section: :pending_reviews)

      expect(response).to have_http_status(:success)
      expect(response.body.strip).to eq("")
    end

    it "renders the reviews block when the cache returns data" do
      review = instance_double(
        Review,
        review_type: "daily_start",
        in_progress?: false,
        persisted?: true,
        progress_percentage: 0,
        to_param: "42"
      )
      allow(Rails.cache).to receive(:read).and_call_original
      allow(Rails.cache).to receive(:read).with(a_string_starting_with("pending_reviews/"))
        .and_return([ { type: "daily_start", review: review } ])

      get fragment_action_items_path(filter: :today, section: :pending_reviews)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Reviews")
      expect(response.body).to include(Review::REVIEW_TYPE_LABELS["daily_start"])
    end
  end

  describe "GET /action_items/fragment/:filter/calendar_events" do
    it "renders nothing when the calendar events cache is empty" do
      allow(Rails.cache).to receive(:read).and_call_original
      allow(Rails.cache).to receive(:read).with("calendar_events_#{Date.current}").and_return([])
      allow(Rails.cache).to receive(:read).with("meetings_by_event_id/v1").and_return({})

      get fragment_action_items_path(filter: :today, section: :calendar_events)

      expect(response).to have_http_status(:success)
      expect(response.body.strip).to eq("")
    end

    it "renders the agenda block when calendar events are present" do
      allow(Rails.cache).to receive(:read).and_call_original
      allow(Rails.cache).to receive(:read).with("calendar_events_#{Date.current}").and_return([
        { event_id: "abc", start_time: Time.current, end_time: Time.current + 1.hour, title: "Standup" }
      ])
      allow(Rails.cache).to receive(:read).with("meetings_by_event_id/v1").and_return({})

      get fragment_action_items_path(filter: :today, section: :calendar_events)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Standup")
    end

    it "uses tomorrow's date when the filter is tomorrow" do
      allow(Rails.cache).to receive(:read).and_call_original
      allow(Rails.cache).to receive(:read).with("calendar_events_#{Date.tomorrow}").and_return([
        { event_id: "xyz", start_time: 1.day.from_now, end_time: 1.day.from_now + 1.hour, title: "Meeting-tomorrow" }
      ])
      allow(Rails.cache).to receive(:read).with("meetings_by_event_id/v1").and_return({})

      get fragment_action_items_path(filter: :tomorrow, section: :calendar_events)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Meeting-tomorrow")
    end
  end

  describe "GET /action_items/fragment/:filter/completed_items" do
    it "renders the recent completed block when there are completed items" do
      create(:action_item, description: "Vandaag klaar", completed_at: 2.hours.ago, due_date: Date.current)

      get fragment_action_items_path(filter: :today, section: :completed_items)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Recent afgerond")
      expect(response.body).to include("Vandaag klaar")
    end

    it "renders the yesterday-empty state when the yesterday filter has no completed items" do
      get fragment_action_items_path(filter: :yesterday, section: :completed_items)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Geen actiepunten afgerond gisteren")
    end

    it "renders yesterday's completed items when the yesterday filter has data" do
      create(:action_item, description: "Gisteren klaar", completed_at: 1.day.ago, due_date: Date.yesterday)

      get fragment_action_items_path(filter: :yesterday, section: :completed_items)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Afgerond gisteren")
      expect(response.body).to include("Gisteren klaar")
    end
  end

  describe "GET /action_items/fragment/:filter/pending_items" do
    it "renders the pending items list for the today filter" do
      create(:action_item, description: "Vandaag te doen", due_date: Date.current)

      get fragment_action_items_path(filter: :today, section: :pending_items)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Openstaand")
      expect(response.body).to include("Vandaag te doen")
    end

    it "renders the empty state when there are no pending items for the filter" do
      get fragment_action_items_path(filter: :today, section: :pending_items)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Geen openstaande actiepunten")
    end

    it "renders an empty body when the filter is yesterday (no pending items ever)" do
      get fragment_action_items_path(filter: :yesterday, section: :pending_items)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Geen openstaande actiepunten")
    end

    it "does not fire per-item children queries when rendering items with sub-items" do
      3.times do
        parent = create(:action_item, due_date: Date.current)
        create(:action_item, parent: parent, due_date: Date.current)
        create(:action_item, parent: parent, due_date: Date.current, completed_at: 1.hour.ago)
      end

      # Prime the request once so route/controller class caches don't skew the count
      get fragment_action_items_path(filter: :today, section: :pending_items)

      queries = []
      callback = ->(*, payload) do
        next if payload[:name] == "SCHEMA"
        next if payload[:sql].match?(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)

        queries << payload[:sql]
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get fragment_action_items_path(filter: :today, section: :pending_items)
      end

      children_scope_queries = queries.grep(/FROM "action_items".*"parent_id" =/)
      expect(children_scope_queries).to be_empty,
        "expected no per-item children scope queries, got:\n#{children_scope_queries.join("\n")}"
    end
  end

  describe "index emits lazy-load shells pointing at the fragment endpoint" do
    it "renders the pending_items, pending_reviews, calendar_events and completed_items lazy shells with staggered delays on /" do
      get today_action_items_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(data-lazy-load-url-value="#{fragment_action_items_path(filter: :today, section: :pending_items)}"))
      expect(response.body).to include(%(data-lazy-load-url-value="#{fragment_action_items_path(filter: :today, section: :pending_reviews)}"))
      expect(response.body).to include(%(data-lazy-load-url-value="#{fragment_action_items_path(filter: :today, section: :calendar_events)}"))
      expect(response.body).to include(%(data-lazy-load-url-value="#{fragment_action_items_path(filter: :today, section: :completed_items)}"))
      expect(response.body).to include(%(data-lazy-load-delay-value="100"))
      expect(response.body).to include(%(data-lazy-load-delay-value="300"))
      expect(response.body).to include(%(data-lazy-load-delay-value="500"))
      expect(response.body).to include(%(data-lazy-load-delay-value="700"))
    end

    it "does not fire any action_items queries on the initial render" do
      create(:action_item, description: "Vandaag te doen", due_date: Date.current)

      # Warm the caches so we don't observe cache-miss enqueue traffic
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

      action_item_queries = queries.grep(/FROM "action_items"/)
      expect(action_item_queries).to be_empty,
        "expected no action_items queries on initial render, got:\n#{action_item_queries.join("\n")}"
    end
  end
end
