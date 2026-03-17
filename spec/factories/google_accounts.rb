FactoryBot.define do
  factory :google_account do
    email { "test@example.com" }
    access_token { "fake_token" }
    refresh_token { "fake_refresh" }
    token_expires_at { 1.hour.from_now }
  end
end
