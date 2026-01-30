class HabitCompletion < ApplicationRecord
  belongs_to :habit

  validates :completed_on, presence: true, uniqueness: { scope: :habit_id }
  validates :count, presence: true, numericality: { greater_than: 0 }

  scope :on_date, ->(date) { where(completed_on: date) }
  scope :in_range, ->(start_date, end_date) { where(completed_on: start_date..end_date) }
end
