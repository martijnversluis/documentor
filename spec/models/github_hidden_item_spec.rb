require "rails_helper"

RSpec.describe GithubHiddenItem, type: :model do
  describe "validations" do
    it "requires item_id" do
      item = GithubHiddenItem.new(action: "snooze")
      expect(item).not_to be_valid
      expect(item.errors[:item_id]).to be_present
    end

    it "requires action" do
      item = GithubHiddenItem.new(item_id: "notification-1")
      expect(item).not_to be_valid
      expect(item.errors[:action]).to be_present
    end

    it "requires unique item_id" do
      GithubHiddenItem.create!(item_id: "notification-1", action: "snooze")
      item = GithubHiddenItem.new(item_id: "notification-1", action: "ignore")
      expect(item).not_to be_valid
      expect(item.errors[:item_id]).to be_present
    end

    it "requires action to be snooze, ignore, or promote" do
      item = GithubHiddenItem.new(item_id: "notification-1", action: "invalid")
      expect(item).not_to be_valid
      expect(item.errors[:action]).to be_present
    end
  end

  describe ".active" do
    it "includes ignored items" do
      item = GithubHiddenItem.create!(item_id: "notification-1", action: "ignore")
      expect(GithubHiddenItem.active).to include(item)
    end

    it "includes promoted items" do
      item = GithubHiddenItem.create!(item_id: "notification-1", action: "promote")
      expect(GithubHiddenItem.active).to include(item)
    end

    it "includes snooze items created today" do
      item = GithubHiddenItem.create!(item_id: "notification-1", action: "snooze")
      expect(GithubHiddenItem.active).to include(item)
    end

    it "excludes snooze items created yesterday" do
      item = GithubHiddenItem.create!(item_id: "notification-1", action: "snooze")
      item.update_column(:created_at, 1.day.ago)
      expect(GithubHiddenItem.active).not_to include(item)
    end
  end

  describe ".hidden_item_ids" do
    it "returns item_ids from active items" do
      GithubHiddenItem.create!(item_id: "notification-1", action: "ignore")
      GithubHiddenItem.create!(item_id: "issue-2", action: "snooze")
      GithubHiddenItem.create!(item_id: "pr-3", action: "promote")

      expect(GithubHiddenItem.hidden_item_ids).to contain_exactly("notification-1", "issue-2", "pr-3")
    end

    it "excludes expired snooze items" do
      GithubHiddenItem.create!(item_id: "notification-1", action: "ignore")
      expired = GithubHiddenItem.create!(item_id: "issue-2", action: "snooze")
      expired.update_column(:created_at, 1.day.ago)

      expect(GithubHiddenItem.hidden_item_ids).to eq(["notification-1"])
    end
  end
end
