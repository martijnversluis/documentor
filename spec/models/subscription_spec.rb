require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe "validations" do
    it "requires name" do
      subscription = Subscription.new(name: nil)
      expect(subscription).not_to be_valid
      expect(subscription.errors[:name]).to be_present
    end

    it "validates cost_frequency inclusion" do
      subscription = Subscription.new(name: "Test", cost_frequency: "invalid")
      expect(subscription).not_to be_valid
      expect(subscription.errors[:cost_frequency]).to be_present
    end

    it "allows valid cost_frequency values" do
      %w[monthly quarterly yearly one_time].each do |freq|
        subscription = Subscription.new(name: "Test", cost_frequency: freq)
        subscription.valid?
        expect(subscription.errors[:cost_frequency]).to be_empty
      end
    end

    it "allows blank cost_frequency" do
      subscription = Subscription.new(name: "Test", cost_frequency: nil)
      subscription.valid?
      expect(subscription.errors[:cost_frequency]).to be_empty
    end
  end

  describe "associations" do
    it "belongs_to dossier optionally" do
      subscription = Subscription.create!(name: "Standalone")
      expect(subscription.dossier).to be_nil

      dossier = Dossier.create!(name: "Test Dossier")
      subscription.update!(dossier: dossier)
      expect(subscription.dossier).to eq(dossier)
    end

    it "has many documents through subscription_documents" do
      subscription = Subscription.create!(name: "Test")
      doc = Document.create!(name: "Test Doc")
      subscription.subscription_documents.create!(document: doc)

      expect(subscription.documents).to eq([doc])
    end

  end

  describe "concerns" do
    it "is taggable" do
      subscription = Subscription.create!(name: "Test")
      subscription.tag_list = "verzekering, auto"
      subscription.save!
      expect(subscription.tags.count).to eq(2)
    end

    it "is party_linkable" do
      subscription = Subscription.create!(name: "Test")
      expect(subscription).to respond_to(:parties)
      expect(subscription).to respond_to(:party_links)
    end

    it "is archivable" do
      subscription = Subscription.create!(name: "Test")
      expect(subscription).not_to be_archived

      subscription.archive!
      expect(subscription).to be_archived

      subscription.unarchive!
      expect(subscription).not_to be_archived
    end
  end

  describe "scopes" do
    it "not_archived excludes archived records" do
      active = Subscription.create!(name: "Active")
      archived = Subscription.create!(name: "Archived")
      archived.archive!

      expect(Subscription.not_archived).to include(active)
      expect(Subscription.not_archived).not_to include(archived)
    end

    it "archived includes only archived records" do
      active = Subscription.create!(name: "Active")
      archived = Subscription.create!(name: "Archived")
      archived.archive!

      expect(Subscription.archived).to include(archived)
      expect(Subscription.archived).not_to include(active)
    end

    it "ordered sorts by name" do
      b = Subscription.create!(name: "Beta")
      a = Subscription.create!(name: "Alpha")
      c = Subscription.create!(name: "Charlie")

      expect(Subscription.ordered.to_a).to eq([a, b, c])
    end
  end

  describe "#active?" do
    it "returns true when no end date" do
      subscription = Subscription.new(name: "Doorlopend")
      expect(subscription).to be_active
    end

    it "returns true when end date in future" do
      subscription = Subscription.new(name: "Future", ends_on: 1.year.from_now)
      expect(subscription).to be_active
    end

    it "returns false when end date in past" do
      subscription = Subscription.new(name: "Expired", ends_on: 1.day.ago)
      expect(subscription).not_to be_active
    end
  end

  describe "#cost_display" do
    it "formats monthly cost" do
      expect(Subscription.new(cost_cents: 1999, cost_frequency: "monthly").cost_display).to eq("19,99 / maand")
    end

    it "formats yearly cost" do
      expect(Subscription.new(cost_cents: 12000, cost_frequency: "yearly").cost_display).to eq("120,00 / jaar")
    end

    it "formats quarterly cost" do
      expect(Subscription.new(cost_cents: 5000, cost_frequency: "quarterly").cost_display).to eq("50,00 / kwartaal")
    end

    it "formats one_time cost" do
      expect(Subscription.new(cost_cents: 25000, cost_frequency: "one_time").cost_display).to eq("250,00 eenmalig")
    end

    it "returns nil when no cost" do
      expect(Subscription.new(cost_cents: nil).cost_display).to be_nil
    end
  end
end
