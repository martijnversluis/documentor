class Habit < ApplicationRecord
  include Archivable

  # Prevent accidental deletion - habits should only be archived
  before_destroy :prevent_destruction

  has_many :habit_completions, dependent: :destroy

  FREQUENCIES = %w[daily weekdays weekly].freeze
  COLORS = %w[blue green purple orange pink red yellow].freeze

  validates :name, presence: true
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }
  validates :color, inclusion: { in: COLORS }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(Arel.sql("position IS NULL, position ASC, created_at ASC")) }

  # Parse target_days from JSON string
  def target_days_array
    return [] if target_days.blank?
    JSON.parse(target_days)
  rescue JSON::ParserError
    []
  end

  # Set target_days from array
  def target_days_array=(days)
    self.target_days = days.is_a?(Array) ? days.to_json : nil
  end

  # Check if habit is scheduled for a specific date
  def scheduled_for?(date)
    case frequency
    when "daily"
      true
    when "weekdays"
      date.wday.between?(1, 5) # Monday to Friday
    when "weekly"
      target_days_array.include?(date.wday)
    else
      true
    end
  end

  # Check if habit was fully completed on a specific date
  def completed_on?(date)
    count = completion_count_for(date)
    if target_count.present?
      count >= target_count
    else
      count >= 1
    end
  end

  # Get completion for a specific date
  def completion_for(date)
    habit_completions.find_by(completed_on: date)
  end

  # Get completion count for a specific date
  def completion_count_for(date)
    completion_for(date)&.count || 0
  end

  # Toggle completion for a date (for single-count habits)
  def toggle_completion!(date)
    completion = completion_for(date)
    if completion
      completion.destroy!
      nil
    else
      habit_completions.create!(completed_on: date, count: 1)
    end
  end

  # Increment completion count for a date
  def increment_completion!(date)
    completion = completion_for(date)
    if completion
      completion.increment!(:count)
    else
      habit_completions.create!(completed_on: date, count: 1)
    end
  end

  # Decrement completion count for a date
  def decrement_completion!(date)
    completion = completion_for(date)
    return unless completion

    if completion.count > 1
      completion.decrement!(:count)
    else
      completion.destroy!
    end
  end

  # Calculate current streak (only counts days where target was fully met)
  def current_streak
    streak = 0
    date = Date.current

    # If not completed today yet, start from yesterday
    date -= 1.day unless completed_on?(date) || !scheduled_for?(date)

    while date >= created_at.to_date
      if scheduled_for?(date)
        if completed_on?(date)
          streak += 1
        else
          break
        end
      end
      date -= 1.day
    end

    streak
  end

  # Check if this habit uses counter mode (vs simple checkbox)
  def counter_mode?
    target_count.present?
  end

  # Calculate completion rate for last N days
  def completion_rate(days: 30)
    start_date = [Date.current - days + 1, created_at.to_date].max
    end_date = Date.current

    scheduled_days = (start_date..end_date).count { |d| scheduled_for?(d) }
    return 0 if scheduled_days.zero?

    completed_days = habit_completions.where(completed_on: start_date..end_date).count
    (completed_days.to_f / scheduled_days * 100).round
  end

  # Get completions for a date range (for calendar display)
  def completions_in_range(start_date, end_date)
    habit_completions.where(completed_on: start_date..end_date).pluck(:completed_on)
  end

  # Color classes for Tailwind
  def color_classes
    case color
    when "blue" then { bg: "bg-blue-500", light: "bg-blue-100", text: "text-blue-600", border: "border-blue-500" }
    when "green" then { bg: "bg-green-500", light: "bg-green-100", text: "text-green-600", border: "border-green-500" }
    when "purple" then { bg: "bg-purple-500", light: "bg-purple-100", text: "text-purple-600", border: "border-purple-500" }
    when "orange" then { bg: "bg-orange-500", light: "bg-orange-100", text: "text-orange-600", border: "border-orange-500" }
    when "pink" then { bg: "bg-pink-500", light: "bg-pink-100", text: "text-pink-600", border: "border-pink-500" }
    when "red" then { bg: "bg-red-500", light: "bg-red-100", text: "text-red-600", border: "border-red-500" }
    when "yellow" then { bg: "bg-yellow-500", light: "bg-yellow-100", text: "text-yellow-600", border: "border-yellow-500" }
    else { bg: "bg-gray-500", light: "bg-gray-100", text: "text-gray-600", border: "border-gray-500" }
    end
  end

  def frequency_label
    case frequency
    when "daily" then "Dagelijks"
    when "weekdays" then "Werkdagen"
    when "weekly" then "Wekelijks"
    else frequency
    end
  end

  private

  def prevent_destruction
    errors.add(:base, "Gewoontes kunnen niet verwijderd worden, alleen gearchiveerd")
    throw(:abort)
  end
end
