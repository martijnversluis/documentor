require "rails_helper"

describe "ApplicationController hot-path cache resilience" do
  around { |ex| Bullet.enable = false; ex.run; Bullet.enable = true }

  before { ApplicationController::PROCESS_CACHE.clear }

  # work_status is only read from the layout when work_mode_auto? is true.
  # Test env uses :null_store, so cache writes are no-ops; stub the read.
  before do
    create(:google_calendar, enabled: true)
    allow(Rails.cache).to receive(:read).and_call_original
    allow(Rails.cache).to receive(:read).with("work_mode_auto").and_return(true)
  end

  # Rack::Timeout::RequestTimeoutException inherits from Exception (not StandardError),
  # so it slips past broad rescues. The hot-path readers must catch it explicitly.
  cache_failures = {
    "ActiveRecord::QueryAborted" => [ActiveRecord::QueryAborted, "statement timeout"],
    "Rack::Timeout::RequestTimeoutException" => [Rack::Timeout::RequestTimeoutException, "Request ran for longer than 15000ms"]
  }

  %w[auto_work_mode work_mode_auto work_status ongoing_meetings].each do |key|
    describe "#{key} hot-path" do
      it "reads the SolidCache-backed value at most once across two requests within the TTL" do
        reads = Hash.new(0)
        allow(Rails.cache).to receive(:read).and_wrap_original do |original, *args, **kwargs|
          reads[args.first] += 1
          # The outer before-block stubs "work_mode_auto" → true (null_store returns
          # nil otherwise), so the layout renders the work_status / ongoing_meetings
          # blocks. Re-apply it here since and_wrap_original replaces the stub.
          args.first == "work_mode_auto" ? true : original.call(*args, **kwargs)
        end

        2.times { get today_action_items_path }

        expect(reads[key]).to eq(1),
          "expected #{key} to be read once (memoized), got #{reads[key]}"
      end

      cache_failures.each do |failure_name, (exception_class, message)|
        it "renders successfully when the underlying cache read raises #{failure_name}" do
          allow(Rails.cache).to receive(:read).and_call_original
          # Preserve the outer work_mode_auto stub so the layout still renders
          # the work_status / ongoing_meetings blocks (otherwise the resilience
          # assertion for those keys passes vacuously — the read never fires).
          allow(Rails.cache).to receive(:read).with("work_mode_auto").and_return(true)
          allow(Rails.cache).to receive(:read).with(key)
            .and_raise(exception_class, message)

          get today_action_items_path

          expect(response).to have_http_status(:success)
          expect(Rails.cache).to have_received(:read).with(key),
            "expected the #{key} cache read to be attempted (and rescued)"
        end
      end
    end
  end

  describe "load_filter_counts resilience" do
    cache_failures.each do |failure_name, (exception_class, message)|
      it "renders successfully when the filter-counts cache read raises #{failure_name}" do
        allow(Rails.cache).to receive(:read).and_call_original
        allow(Rails.cache).to receive(:read).with("work_mode_auto").and_return(true)
        allow(Rails.cache).to receive(:read).with(a_string_starting_with("action_items/filter_counts/"))
          .and_raise(exception_class, message)

        get today_action_items_path

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "work_dossier_ids resilience" do
    cache_failures.each do |failure_name, (exception_class, message)|
      it "falls back to a direct query when the cache fetch raises #{failure_name}" do
        allow(Rails.cache).to receive(:fetch).and_call_original
        allow(Rails.cache).to receive(:fetch).with("work_dossier_ids/v1", anything)
          .and_raise(exception_class, message)

        get today_action_items_path

        expect(response).to have_http_status(:success)
      end
    end
  end
end
