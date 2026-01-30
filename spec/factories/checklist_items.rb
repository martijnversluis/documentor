FactoryBot.define do
  factory :checklist_item do
    checklist { nil }
    description { "MyText" }
    position { 1 }
    context { "MyString" }
    estimated_minutes { 1 }
  end
end
