FactoryBot.define do
  factory :note do
    title { "MyString" }
    content { "MyText" }
    dossier { nil }
    folder { nil }
    occurred_at { "2026-01-01 21:18:38" }
  end
end
