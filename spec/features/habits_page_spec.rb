require 'rails_helper'

RSpec.describe "Habits page", type: :feature do
  it "renders the habits index without N+1 queries" do
    habits = create_list(:habit, 3, created_at: 30.days.ago)
    habits.each do |habit|
      5.times do |i|
        create(:habit_completion, habit: habit, completed_on: i.days.ago.to_date)
      end
    end

    visit habits_path

    expect(page).to have_content("Gewoontes")
    habits.each { |h| expect(page).to have_content(h.name) }
  end

  it "lets the user pick an option for a choice habit and toggle it off" do
    create(
      :habit,
      name: "Hoe was je dag?",
      choice_options_text: "😞 Slecht\n😐 Matig\n🙂 Goed\n😄 Top",
    )

    visit habits_path

    expect(page).to have_content("Hoe was je dag?")
    # Each choice option button shows the emoji as title text
    expect(page).to have_button("Slecht")
    expect(page).to have_button("Top")

    # Picking an option records a completion for today
    expect { click_button "Goed", match: :first }
      .to change { HabitCompletion.where(choice_value: "🙂").count }.from(0).to(1)

    # Clicking the same option again clears it
    expect { click_button "Goed", match: :first }
      .to change { HabitCompletion.count }.by(-1)
  end
end
