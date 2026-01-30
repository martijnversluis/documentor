FactoryBot.define do
  factory :expiring_item do
    name { "MyString" }
    expires_at { "2026-01-25" }
    description { "MyText" }
    notify_days_before { 1 }
  end
end
