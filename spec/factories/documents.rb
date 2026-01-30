FactoryBot.define do
  factory :document do
    name { "MyString" }
    dossier { nil }
    folder { nil }
    content_text { "MyText" }
    occurred_at { "2026-01-01 21:18:37" }
  end
end
