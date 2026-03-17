FactoryBot.define do
  factory :google_calendar do
    google_account
    sequence(:calendar_id) { |n| "calendar#{n}@group.calendar.google.com" }
    name { "My Calendar" }
    color { "#4285f4" }
    enabled { true }
  end
end
