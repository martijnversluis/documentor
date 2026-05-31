FactoryBot.define do
  factory :action_item do
    description { "MyText" }
    due_date { nil }
    completed_at { nil }
  end
end
