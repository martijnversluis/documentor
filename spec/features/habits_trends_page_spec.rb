require 'rails_helper'

RSpec.describe "Habits trends page", type: :feature do
  it "renders the trends heatmap for active habits" do
    habit_a = create(:habit, name: "Meditatie", color: "green", created_at: 60.days.ago)
    habit_b = create(:habit, name: "Sport", color: "orange", created_at: 60.days.ago)

    3.times do |i|
      create(:habit_completion, habit: habit_a, completed_on: i.days.ago.to_date)
    end
    create(:habit_completion, habit: habit_b, completed_on: 1.day.ago.to_date)

    visit trends_habits_path

    expect(page).to have_content("Trends")
    expect(page).to have_content("Meditatie")
    expect(page).to have_content("Sport")
    expect(page).to have_content("Alle habits samen")
  end

  it "supports switching the period" do
    create(:habit, name: "Meditatie", created_at: 200.days.ago)

    visit trends_habits_path(days: 180)

    expect(page).to have_current_path(trends_habits_path(days: 180))
    expect(page).to have_content("Meditatie")
  end

  it "shows an empty state when there are no active habits" do
    visit trends_habits_path

    expect(page).to have_content("Nog geen actieve gewoontes")
  end

  it "renders a sparkline for choice habits with the value scale" do
    habit = create(
      :habit,
      name: "Hoe was je dag?",
      color: "purple",
      choice_options_text: "😞 Slecht\n😐 Matig\n🙂 Goed\n😄 Top",
      created_at: 30.days.ago
    )
    create(:habit_completion, habit: habit, completed_on: 2.days.ago.to_date, choice_value: "🙂")
    create(:habit_completion, habit: habit, completed_on: 1.day.ago.to_date, choice_value: "😄")

    visit trends_habits_path

    expect(page).to have_content("Hoe was je dag?")
    expect(page).to have_content("↑ 😄 · 😞 ↓")
    expect(page).to have_css("svg circle", minimum: 2)
  end
end
