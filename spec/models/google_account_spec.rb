require "rails_helper"

RSpec.describe GoogleAccount do
  describe "#sync_calendars!" do
    let(:account) { create(:google_account) }
    let(:google_calendars_from_api) do
      [
        { id: "primary@example.com", name: "Primary", color: "#4285f4", primary: true },
        { id: "work@group.calendar.google.com", name: "Work", color: "#7986cb", primary: false },
        { id: "holidays@group.calendar.google.com", name: "Holidays", color: "#0b8043", primary: false }
      ]
    end
    let(:service) { instance_double(GoogleCalendarService, calendars: google_calendars_from_api) }

    before do
      allow(GoogleCalendarService).to receive(:new).with(account).and_return(service)
    end

    it "creates new calendars from Google" do
      expect { account.sync_calendars! }.to change { account.google_calendars.count }.from(0).to(3)
    end

    it "enables only the primary calendar for new calendars" do
      account.sync_calendars!

      expect(account.google_calendars.find_by(calendar_id: "primary@example.com")).to be_enabled
      expect(account.google_calendars.find_by(calendar_id: "work@group.calendar.google.com")).not_to be_enabled
      expect(account.google_calendars.find_by(calendar_id: "holidays@group.calendar.google.com")).not_to be_enabled
    end

    it "does not overwrite enabled status for existing calendars" do
      create(:google_calendar, google_account: account, calendar_id: "work@group.calendar.google.com", name: "Work", enabled: true)
      create(:google_calendar, google_account: account, calendar_id: "primary@example.com", name: "Primary", enabled: false)

      account.sync_calendars!

      expect(account.google_calendars.find_by(calendar_id: "work@group.calendar.google.com")).to be_enabled
      expect(account.google_calendars.find_by(calendar_id: "primary@example.com")).not_to be_enabled
    end

    it "updates name and color for existing calendars" do
      create(:google_calendar, google_account: account, calendar_id: "primary@example.com", name: "Old Name", color: "#000000")

      account.sync_calendars!

      calendar = account.google_calendars.find_by(calendar_id: "primary@example.com")
      expect(calendar.name).to eq("Primary")
      expect(calendar.color).to eq("#4285f4")
    end

    it "removes calendars that no longer exist in Google" do
      create(:google_calendar, google_account: account, calendar_id: "deleted@group.calendar.google.com", name: "Deleted")

      account.sync_calendars!

      expect(account.google_calendars.find_by(calendar_id: "deleted@group.calendar.google.com")).to be_nil
    end
  end
end
