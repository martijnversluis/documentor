FactoryBot.define do
  factory :habit do
    sequence(:name) { |n| "Gewoonte #{n}" }
    frequency { "daily" }
    color { "blue" }
    active { true }
  end

  factory :habit_completion do
    habit
    completed_on { Date.current }
    count { 1 }
  end
end
