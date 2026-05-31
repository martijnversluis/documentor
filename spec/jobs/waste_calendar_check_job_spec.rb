describe WasteCalendarCheckJob do
  before do
    AppSetting["waste_calendar_post_code"] = "1234AB"
    AppSetting["waste_calendar_house_number"] = "1"
  end

  it "creates an action item for each pickup scheduled for tomorrow" do
    WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")
    WastePickup.create!(collection_date: Date.tomorrow, waste_type: "GFT")

    expect { described_class.new.perform }.to change(ActionItem, :count).by(2)

    descriptions = ActionItem.where(due_date: Date.current).pluck(:description)
    expect(descriptions).to contain_exactly(
      "Grijze kliko aan de weg zetten",
      "Groene kliko aan de weg zetten",
    )
  end

  it "creates a readable description for every normalized waste type" do
    %w[REST GFT PAPIER PMD GLAS TEXTIEL].each do |waste_type|
      WastePickup.delete_all
      ActionItem.delete_all
      WastePickup.create!(collection_date: Date.tomorrow, waste_type: waste_type)

      described_class.new.perform

      item = ActionItem.find_by(notes: "waste_type:#{waste_type}")
      expect(item).not_to be_nil, "expected an action item for #{waste_type}"
      expect(item.description).not_to match(/\A[A-Z]+ aan de weg/), "#{waste_type} fell back to raw type"
    end
  end

  it "creates the action item without a context so it does not depend on TaskContext setup" do
    WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")

    expect { described_class.new.perform }.to change(ActionItem, :count).by(1)
    expect(ActionItem.last.context).to be_nil
  end

  it "does not create duplicates when run twice for the same pickup" do
    WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")

    described_class.new.perform
    expect { described_class.new.perform }.not_to change(ActionItem, :count)
  end

  it "does nothing when no pickup is scheduled for tomorrow" do
    WastePickup.create!(collection_date: Date.current + 5.days, waste_type: "REST")

    expect { described_class.new.perform }.not_to change(ActionItem, :count)
  end

  it "does nothing when the post code and house number have not been configured" do
    AppSetting["waste_calendar_post_code"] = nil
    AppSetting["waste_calendar_house_number"] = nil
    WastePickup.create!(collection_date: Date.tomorrow, waste_type: "REST")

    expect { described_class.new.perform }.not_to change(ActionItem, :count)
  end
end
