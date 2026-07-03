require 'rails_helper'

RSpec.describe Dossier, type: :model do
  describe "#timeline_items" do
    let(:dossier) { create(:dossier, name: "Test") }

    it "returns documents and notes sorted by display_date descending" do
      folder = create(:folder, dossier: dossier)
      older = create(:document, dossier: dossier, name: "older", occurred_at: 3.days.ago)
      newer = create(:note, dossier: dossier, folder: folder, title: "newer", occurred_at: 1.day.ago)
      middle = create(:document, dossier: dossier, folder: folder, name: "middle", occurred_at: 2.days.ago)

      expect(dossier.timeline_items).to eq([newer, middle, older])
    end

    it "does not include documents linked to a subscription" do
      kept = create(:document, dossier: dossier, name: "kept")
      hidden = create(:document, dossier: dossier, name: "hidden")
      subscription = Subscription.create!(name: "Test", dossier: dossier)
      SubscriptionDocument.create!(subscription: subscription, document: hidden)

      timeline = dossier.timeline_items
      expect(timeline).to include(kept)
      expect(timeline).not_to include(hidden)
    end

    it "avoids N+1 queries for folder lookups" do
      folder_a = create(:folder, dossier: dossier)
      folder_b = create(:folder, dossier: dossier)
      create(:document, dossier: dossier, folder: folder_a, name: "doc-a")
      create(:document, dossier: dossier, folder: folder_b, name: "doc-b")
      create(:note, dossier: dossier, folder: folder_a, title: "note-a")
      create(:note, dossier: dossier, folder: folder_b, title: "note-b")

      dossier.reload

      queries = []
      callback = ->(_name, _start, _finish, _id, payload) do
        queries << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:sql].start_with?("BEGIN", "COMMIT", "SAVEPOINT", "RELEASE")
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        dossier.timeline_items.each { |item| item.folder&.name }
      end

      expect(queries.size).to be <= 5
    end
  end
end
