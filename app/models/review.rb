class Review < ApplicationRecord
  REVIEW_TYPES = %w[daily_start daily_end weekly monthly quarterly yearly].freeze
  REVIEW_TYPE_LABELS = {
    "daily_start" => "Dag start",
    "daily_end" => "Dag eind",
    "weekly" => "Wekelijkse",
    "monthly" => "Maandelijkse",
    "quarterly" => "Kwartaal",
    "yearly" => "Jaarlijkse"
  }.freeze

  has_many :review_steps, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :review

  validates :review_type, presence: true, inclusion: { in: REVIEW_TYPES }
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :period_key, presence: true, uniqueness: { scope: :review_type }

  scope :by_type, ->(type) { where(review_type: type) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :in_progress, -> { where.not(started_at: nil).where(completed_at: nil) }
  scope :for_year, ->(year) { where(period_start: Date.new(year, 1, 1)..Date.new(year, 12, 31)) }
  scope :ordered, -> { order(period_start: :desc) }

  def status
    return "completed" if completed_at.present?
    return "paused" if paused_at.present? && started_at.present?
    return "in_progress" if started_at.present?
    "not_started"
  end

  def completed?
    completed_at.present?
  end

  def in_progress?
    started_at.present? && completed_at.nil?
  end

  def paused?
    paused_at.present? && completed_at.nil?
  end

  def not_started?
    started_at.nil?
  end

  def current_step
    review_steps.find_by(position: current_step_position)
  end

  def next_pending_step
    review_steps.where(status: "pending").order(position: :asc).first
  end

  def progress_percentage
    return 0 if review_steps.empty?
    completed_count = review_steps.where(status: %w[completed skipped]).count
    (completed_count.to_f / review_steps.count * 100).round
  end

  def completion_status
    return :not_done if not_started?
    return :complete if completed?
    :partial
  end

  def review_type_label
    REVIEW_TYPE_LABELS[review_type]
  end

  # When the review should ideally be done (end of period)
  def due_date
    case review_type
    when "daily_start"
      period_start # Due at start of day
    when "daily_end"
      period_end # Due at end of day
    when "weekly"
      # Due on Friday (or last workday of the week)
      period_end.beginning_of_week + 4.days # Friday
    when "monthly"
      period_end # Last day of month
    when "quarterly"
      period_end # Last day of quarter
    when "yearly"
      period_end # Last day of year
    else
      period_end
    end
  end

  def due?
    return false if completed?
    Date.current >= due_date
  end

  def due_soon?
    return false if completed? || due?
    case review_type
    when "weekly"
      false # Weekly reviews only show on Friday (due date)
    when "monthly"
      Date.current >= due_date - 2.days # Last 3 days of month
    when "quarterly"
      Date.current >= due_date - 6.days # Last week of quarter
    when "yearly"
      Date.current >= due_date - 13.days # Last 2 weeks of year
    else
      false
    end
  end

  def start!
    return if started_at.present?

    template = ReviewTemplate.active_for_type(review_type)
    return false unless template&.review_template_steps&.any?

    transaction do
      template.review_template_steps.each do |template_step|
        review_steps.create!(
          review_template_step: template_step,
          title: template_step.title,
          description: template_step.description,
          position: template_step.position
        )
      end

      update!(
        started_at: Time.current,
        paused_at: nil,
        current_step_position: review_steps.minimum(:position) || 0
      )
    end
    true
  end

  def resume!
    update!(paused_at: nil) if paused?
  end

  def pause!
    update!(paused_at: Time.current) if in_progress? && !paused?
  end

  def complete!
    update!(completed_at: Time.current, paused_at: nil) if in_progress?
  end

  def advance_to_next_step!
    next_step = next_pending_step
    if next_step
      update!(current_step_position: next_step.position)
    else
      complete!
    end
  end

  # Class methods for period calculations
  class << self
    def period_for(type, date = Date.current)
      case type
      when "daily_start"
        start_date = date
        end_date = date
        key = "#{date.strftime('%Y-%m-%d')}-start"
      when "daily_end"
        start_date = date
        end_date = date
        key = "#{date.strftime('%Y-%m-%d')}-end"
      when "weekly"
        start_date = date.beginning_of_week
        end_date = date.end_of_week
        key = "#{date.cwyear}-W#{date.strftime('%V')}"
      when "monthly"
        start_date = date.beginning_of_month
        end_date = date.end_of_month
        key = date.strftime("%Y-%m")
      when "quarterly"
        quarter = ((date.month - 1) / 3) + 1
        start_date = Date.new(date.year, (quarter - 1) * 3 + 1, 1)
        end_date = (start_date + 2.months).end_of_month
        key = "#{date.year}-Q#{quarter}"
      when "yearly"
        start_date = date.beginning_of_year
        end_date = date.end_of_year
        key = date.year.to_s
      end
      { start: start_date, end: end_date, key: key }
    end

    def find_or_initialize_for_period(type, date = Date.current)
      period = period_for(type, date)
      find_or_initialize_by(
        review_type: type,
        period_key: period[:key]
      ) do |review|
        review.period_start = period[:start]
        review.period_end = period[:end]
      end
    end

    def current_for_type(type)
      period = period_for(type)
      find_by(review_type: type, period_key: period[:key])
    end

    def exists_for_period?(type, date = Date.current)
      period = period_for(type, date)
      exists?(review_type: type, period_key: period[:key])
    end
  end
end
