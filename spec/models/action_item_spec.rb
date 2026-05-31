require "rails_helper"

RSpec.describe ActionItem do
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
  end
end
