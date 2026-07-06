require "rails_helper"

RSpec.describe Party, type: :model do
  describe "validations" do
    it "requires a name" do
      expect(described_class.new(name: nil)).not_to be_valid
    end

    it "enforces case-insensitive uniqueness on name" do
      described_class.create!(name: "Acme BV")
      duplicate = described_class.new(name: "acme bv")
      expect(duplicate).not_to be_valid
    end
  end

  describe "contact fields" do
    it "persists phone, email, address, postal_code, city and website" do
      party = described_class.create!(
        name: "Acme BV",
        phone: "020-1234567",
        email: "info@acme.example",
        address: "Kerkstraat 1",
        postal_code: "1234 AB",
        city: "Amsterdam",
        website: "https://acme.example"
      )

      party.reload
      expect(party).to have_attributes(
        phone: "020-1234567",
        email: "info@acme.example",
        address: "Kerkstraat 1",
        postal_code: "1234 AB",
        city: "Amsterdam",
        website: "https://acme.example"
      )
    end
  end

  describe "#action_items" do
    it "returns the action items directly associated with the party" do
      party = described_class.create!(name: "Klant X")
      linked = create(:action_item, party: party)
      other = create(:action_item)

      expect(party.action_items).to include(linked)
      expect(party.action_items).not_to include(other)
    end
  end
end
