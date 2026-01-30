FactoryBot.define do
  factory :action_item do
    dossier { nil }
    description { "MyText" }
    due_date { "2026-01-01" }
    completed { false }
    completed_at { "2026-01-01 21:38:35" }
  end
end
