require "rails_helper"

RSpec.describe ActionItem do
  include ActiveSupport::Testing::TimeHelpers

  def count_queries(&)
    queries = 0
    callback = ->(*, payload) do
      next if payload[:name] == "SCHEMA"
      next if payload[:sql].match?(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)

      queries += 1
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)
    queries
  end

  describe ".filter_counts" do
    it "returns counts for each filter category in a single query" do
      create(:action_item, due_date: Date.current, completed_at: nil, someday: false)
      create(:action_item, due_date: Date.current - 2.days, completed_at: nil, someday: false)
      create(:action_item, due_date: Date.tomorrow, completed_at: nil, someday: false)
      create(:action_item, completed_at: Date.yesterday.midday, someday: false, due_date: nil)
      create(:action_item, completed_at: nil, someday: true, due_date: nil)
      create(:action_item, completed_at: nil, someday: false, next_action: true, due_date: nil)
      create(:action_item, completed_at: nil, someday: false, recurrence: "weekly", due_date: nil)
      create(:action_item, completed_at: nil, someday: false, estimated_minutes: 10, due_date: nil)
      create(:action_item, completed_at: nil, someday: false, waiting_for_description: "iemand", due_date: nil)
      create(:action_item, completed_at: nil, someday: false, dossier_id: nil, due_date: nil)

      result = nil
      queries = count_queries { result = described_class.filter_counts(described_class.all) }

      expect(queries).to eq(1)
      expect(result).to include(
        today: 2,
        tomorrow: 1,
        yesterday: 1,
        overdue: 1,
        waiting: 1,
        someday: 1,
        quick: 1,
        next: 1,
        recurring: 1,
      )
      expect(result[:inbox]).to be >= 1
    end

    it "excludes subitems (root_items only)" do
      parent = create(:action_item, completed_at: nil, someday: false, due_date: Date.current)
      create(:action_item, completed_at: nil, someday: false, due_date: Date.current, parent: parent)

      expect(described_class.filter_counts(described_class.all)[:today]).to eq(1)
    end

    it "respects the provided scope" do
      dossier = create(:dossier)
      create(:action_item, completed_at: nil, someday: false, due_date: Date.current, dossier: dossier)
      create(:action_item, completed_at: nil, someday: false, due_date: Date.current, dossier: nil)

      counts = described_class.filter_counts(described_class.where(dossier_id: dossier.id))

      expect(counts[:today]).to eq(1)
    end

  end

  describe "children helpers with preloaded association" do
    let!(:parent) { create(:action_item) }
    let!(:pending_child) { create(:action_item, parent: parent) }
    let!(:completed_child) { create(:action_item, parent: parent, completed_at: 1.hour.ago) }

    let(:loaded_parent) { ActionItem.includes(:children).find(parent.id) }

    it "answers #has_children? without firing a query when children are preloaded" do
      loaded_parent.children.to_a # force load

      expect(count_queries { loaded_parent.has_children? }).to eq(0)
      expect(loaded_parent.has_children?).to be true
    end

    it "answers #pending_children_count without firing a query when children are preloaded" do
      loaded_parent.children.to_a

      count = nil
      queries = count_queries { count = loaded_parent.pending_children_count }

      expect(queries).to eq(0)
      expect(count).to eq(1)
    end

    it "answers #all_children_completed? without firing a query when children are preloaded" do
      loaded_parent.children.to_a

      result = nil
      queries = count_queries { result = loaded_parent.all_children_completed? }

      expect(queries).to eq(0)
      expect(result).to be false
    end

    it "still falls back to a query when children are not preloaded" do
      fresh = ActionItem.find(parent.id)

      expect(count_queries { fresh.has_children? }).to eq(1)
    end
  end

  describe "due_time" do
    it "is optional" do
      item = build(:action_item, description: "test", due_date: Date.current, due_time: nil)
      expect(item).to be_valid
    end

    it "allows a time together with a date" do
      item = build(:action_item, description: "test", due_date: Date.current, due_time: "09:30")
      expect(item).to be_valid
    end

    it "requires due_date when due_time is given" do
      item = build(:action_item, description: "test", due_date: nil, due_time: "09:30")
      expect(item).not_to be_valid
      expect(item.errors[:due_time]).to be_present
    end
  end

  describe ".today with due_time" do
    it "hides items whose due_time is still in the future today" do
      travel_to Time.zone.local(2026, 10, 27, 9, 0) do
        create(:action_item, description: "later", due_date: Date.current, due_time: "14:00")
        shown = create(:action_item, description: "now", due_date: Date.current, due_time: nil)
        early = create(:action_item, description: "early", due_date: Date.current, due_time: "08:00")

        expect(described_class.today).to contain_exactly(shown, early)
      end
    end

    it "always shows overdue items regardless of due_time" do
      travel_to Time.zone.local(2026, 10, 27, 9, 0) do
        yesterday_evening = create(:action_item, description: "y", due_date: Date.yesterday, due_time: "22:00")

        expect(described_class.today).to include(yesterday_evening)
      end
    end
  end

  describe "#active_now?" do
    it "is true when due_time is blank" do
      item = build(:action_item, due_date: Date.current, due_time: nil)
      expect(item.active_now?).to be true
    end

    it "is true when the due_time has passed today" do
      travel_to Time.zone.local(2026, 10, 27, 10, 0) do
        item = build(:action_item, due_date: Date.current, due_time: "09:00")
        expect(item.active_now?).to be true
      end
    end

    it "is false when due_time is still ahead today" do
      travel_to Time.zone.local(2026, 10, 27, 10, 0) do
        item = build(:action_item, due_date: Date.current, due_time: "11:00")
        expect(item.active_now?).to be false
      end
    end

    it "is true for a past-dated item regardless of due_time" do
      travel_to Time.zone.local(2026, 10, 27, 10, 0) do
        item = build(:action_item, due_date: Date.yesterday, due_time: "23:00")
        expect(item.active_now?).to be true
      end
    end
  end

  describe "#complete! for recurring items with due_time" do
    it "copies due_time onto the next occurrence" do
      item = create(
        :action_item,
        description: "standup",
        due_date: Date.current,
        due_time: "09:15",
        recurrence: "daily"
      )

      expect { item.complete! }.to change(described_class, :count).by(1)

      next_item = described_class.where.not(id: item.id).order(:created_at).last
      expect(next_item.due_time.strftime("%H:%M")).to eq("09:15")
      expect(next_item.due_date).to eq(Date.current + 1.day)
    end
  end
end
