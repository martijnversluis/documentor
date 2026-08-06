require "rails_helper"

describe "ApplicationController hot-path cache resilience" do
  around { |ex| Bullet.enable = false; ex.run; Bullet.enable = true }

  before { ApplicationController::PROCESS_CACHE.clear }

  # work_status is only read from the layout when work_mode_auto? is true (i.e. at
  # least one enabled google_calendar exists), so we ensure that condition here.
  before { create(:google_calendar, enabled: true) }

  %w[auto_work_mode work_status ongoing_meetings].each do |key|
    describe "#{key} hot-path" do
      it "reads the SolidCache-backed value at most once across two requests within the TTL" do
        reads = Hash.new(0)
        allow(Rails.cache).to receive(:read).and_wrap_original do |original, *args, **kwargs|
          reads[args.first] += 1
          original.call(*args, **kwargs)
        end

        2.times { get today_action_items_path }

        expect(reads[key]).to eq(1),
          "expected #{key} to be read once (memoized), got #{reads[key]}"
      end

      it "renders successfully when the underlying cache read raises" do
        allow(Rails.cache).to receive(:read).and_call_original
        allow(Rails.cache).to receive(:read).with(key)
          .and_raise(ActiveRecord::QueryAborted, "statement timeout")

        get today_action_items_path

        expect(response).to have_http_status(:success)
      end
    end
  end
end
