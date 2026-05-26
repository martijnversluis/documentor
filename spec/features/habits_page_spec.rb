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
end
