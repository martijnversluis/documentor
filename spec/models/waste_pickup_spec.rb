require "rails_helper"

RSpec.describe WastePickup do
  describe "action item lifecycle" do
    it "creates an action item due the day before the pickup" do
      pickup = WastePickup.create!(collection_date: Date.current + 3.days, waste_type: "REST")

      item = pickup.linked_action_items.first
      expect(item).not_to be_nil
      expect(item.description).to eq("Grijze kliko aan de weg zetten")
      expect(item.due_date).to eq(pickup.collection_date - 1.day)
      expect(item.completed_at).to be_nil
    end

    it "stores the waste_type in the notes so the view can render an icon" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      expect(pickup.linked_action_items.first.notes).to include("waste_type:REST")
    end

    it "creates action items for every upcoming pickup, not only tomorrow's" do
      near = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "GFT")
      far = WastePickup.create!(collection_date: Date.current + 2.weeks, waste_type: "REST")

      expect(near.linked_action_items).to exist
      expect(far.linked_action_items).to exist
    end

    it "is idempotent across saves" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      expect { pickup.touch }.not_to change(ActionItem, :count)
    end

    it "updates the linked action item in place when the pickup changes" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      item = pickup.linked_action_items.first

      pickup.update!(waste_type: "GFT")
      expect(item.reload.description).to eq("Groene kliko aan de weg zetten")
      expect(pickup.linked_action_items.count).to eq(1)
    end

    it "falls back to a readable description for unknown types" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "EXOTIC")
      expect(pickup.linked_action_items.first.description).to eq("EXOTIC aan de weg zetten")
    end

    it "removes the linked action item when the pickup is destroyed and the item is still pending" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      expect(pickup.linked_action_items).to exist

      pickup_id = pickup.id
      pickup.destroy!
      expect(ActionItem.where("notes LIKE ?", "%waste_pickup:#{pickup_id}")).not_to exist
    end

    it "keeps completed action items around when the pickup is destroyed" do
      pickup = WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
      item = pickup.linked_action_items.first
      item.update!(completed_at: Time.current)

      pickup.destroy!
      expect(ActionItem.exists?(item.id)).to be(true)
    end
  end
end
