class ActionItem < ApplicationRecord
  include PgSearch::Model

  belongs_to :dossier, optional: true, touch: true
  belongs_to :waiting_for_party, class_name: "Party", optional: true
  belongs_to :parent, class_name: "ActionItem", optional: true, touch: true
  belongs_to :meeting, optional: true
  has_many :children, class_name: "ActionItem", foreign_key: :parent_id, dependent: :destroy
  has_many :action_item_documents, dependent: :destroy
  has_many :documents, through: :action_item_documents

  pg_search_scope :search,
    against: [:description],
    associated_against: {
      dossier: [:name]
    },
    using: {
      tsearch: { prefix: true }
    }

  RECURRENCE_OPTIONS = %w[daily workdays weekly monthly quarterly yearly].freeze
  validates :description, presence: true
  validates :recurrence, inclusion: { in: RECURRENCE_OPTIONS }, allow_blank: true
  validate :context_must_exist
  validate :children_must_be_completed_before_parent, on: :update, if: -> { completed_at_changed? && completed? }

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :completed_today, -> { completed.where(completed_at: Date.current.all_day) }
  scope :completed_yesterday, -> { completed.where(completed_at: Date.yesterday.all_day) }
  scope :due_today, -> { pending.where(due_date: Date.current) }
  scope :overdue, -> { pending.where(due_date: ...Date.current) }
  scope :today, -> { pending.where(due_date: ..Date.current) }
  scope :tomorrow, -> { pending.where(due_date: Date.tomorrow) }
  scope :upcoming, -> { pending.where(due_date: Date.current..7.days.from_now.to_date) }
  scope :ordered, -> { order(Arel.sql("position IS NULL, position ASC, due_date IS NULL, due_date ASC, created_at ASC")) }
  scope :inbox, -> { where(dossier_id: nil) }
  scope :assigned, -> { where.not(dossier_id: nil) }
  scope :with_context, ->(context) { where(context: context) }
  scope :waiting, -> { where.not(waiting_for_party_id: nil).or(where.not(waiting_for_description: [nil, ""])) }
  scope :not_waiting, -> { where(waiting_for_party_id: nil, waiting_for_description: [nil, ""]) }
  scope :someday_maybe, -> { where(someday: true) }
  scope :active, -> { where(someday: false) }
  scope :quick_wins, -> {
    where(estimated_minutes: 1..15)
      .where("recurrence IS NULL OR due_date <= ?", 1.week.from_now.to_date)
  }
  scope :next_actions, -> { where(next_action: true) }
  scope :recurring, -> { where.not(recurrence: [nil, ""]) }
  scope :root_items, -> { where(parent_id: nil) }

  DURATION_OPTIONS = [
    ["5 min", 5],
    ["15 min", 15],
    ["30 min", 30],
    ["1 uur", 60],
    ["2+ uur", 120]
  ].freeze

  def completed?
    completed_at.present?
  end

  def overdue?
    !completed? && due_date.present? && due_date < Date.current
  end

  def due_today?
    !completed? && due_date == Date.current
  end

  def recurring?
    recurrence.present?
  end

  def waiting?
    waiting_for_party_id.present? || waiting_for_description.present?
  end

  def waiting_for_display
    return nil unless waiting?
    waiting_for_party&.name || waiting_for_description
  end

  def has_children?
    children.exists?
  end

  def pending_children_count
    children.pending.count
  end

  def all_children_completed?
    children.pending.empty?
  end

  def depth
    parent ? parent.depth + 1 : 0
  end

  def root
    parent ? parent.root : self
  end

  def toggle!
    if completed?
      update!(completed_at: nil)
    else
      complete!
    end
  end

  def complete!
    transaction do
      update!(completed_at: Time.current)
      schedule_next_occurrence if recurring?
    end
  end

  private

  def schedule_next_occurrence
    next_due_date = calculate_next_due_date
    return unless next_due_date

    ActionItem.create!(
      dossier: dossier,
      description: description,
      due_date: next_due_date,
      recurrence: recurrence,
      context: context,
      waiting_for_party_id: waiting_for_party_id,
      waiting_for_description: waiting_for_description,
      estimated_minutes: estimated_minutes
    )
  end

  def calculate_next_due_date
    base_date = due_date || Date.current

    case recurrence
    when "daily"
      base_date + 1.day
    when "workdays"
      next_date = base_date + 1.day
      # Skip weekends (Saturday = 6, Sunday = 0)
      next_date += 1.day while next_date.wday == 0 || next_date.wday == 6
      next_date
    when "weekly"
      base_date + 1.week
    when "monthly"
      base_date + 1.month
    when "quarterly"
      base_date + 3.months
    when "yearly"
      base_date + 1.year
    end
  end

  def context_must_exist
    return if context.blank?
    unless TaskContext.exists?(name: context)
      errors.add(:context, "is ongeldig")
    end
  end

  def children_must_be_completed_before_parent
    if children.pending.exists?
      errors.add(:base, "Kan niet afronden: er zijn nog open sub-items")
    end
  end
end
