require "rails_helper"

RSpec.describe WastePickup do
  describe "action item lifecycle" do
    it "creates an action item due the day before the pickup" do
      pickup = WastePickup.create!(collection_date: Date.current + 3.days, waste_type: "REST")

      item = ActionItem.find_by(notes: "waste_pickup:#{pickup.id}")
      expect(item).not_to be_nil
      expect(item.description).to eq("Grijze kliko aan de weg zetten")
      expect(item.due_date).to eq(pickup.collection_date - 1.day)
      expect(item.completed_at).to be_nil
    end

    it "creates action items for every upcoming pickup, not only tomorrow's" do
      near = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "GFT")
      far = WastePickup.create!(collection_date: Date.current + 2.weeks, waste_type: "REST")

      expect(ActionItem.find_by(notes: "waste_pickup:#{near.id}")).not_to be_nil
      expect(ActionItem.find_by(notes: "waste_pickup:#{far.id}")).not_to be_nil
    end

    it "is idempotent across saves" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      expect { pickup.touch }.not_to change(ActionItem, :count)
    end

    it "falls back to a readable description for unknown types" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "EXOTIC")
      item = ActionItem.find_by(notes: "waste_pickup:#{pickup.id}")
      expect(item.description).to eq("EXOTIC aan de weg zetten")
    end

    it "removes the linked action item when the pickup is destroyed and the item is still pending" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      notes = "waste_pickup:#{pickup.id}"
      expect(ActionItem.find_by(notes: notes)).not_to be_nil

      pickup.destroy!
      expect(ActionItem.find_by(notes: notes)).to be_nil
    end

    it "keeps completed action items around when the pickup is destroyed" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      item = ActionItem.find_by(notes: "waste_pickup:#{pickup.id}")
      item.update!(completed_at: Time.current)

      pickup.destroy!
      expect(ActionItem.exists?(item.id)).to be(true)
    end
  end
end
