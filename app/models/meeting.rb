class Meeting < ApplicationRecord
  include PgSearch::Model

  belongs_to :google_account
  has_many :action_items, dependent: :nullify

  validates :google_event_id, presence: true, uniqueness: { scope: :google_account_id }

  pg_search_scope :search,
    against: [:title, :notes],
    using: {
      tsearch: { prefix: true, dictionary: "dutch" }
    }

  scope :with_content, -> { where("notes IS NOT NULL AND notes != ''").or(where(id: ActionItem.where.not(meeting_id: nil).select(:meeting_id))) }
  scope :recent, -> { order(start_time: :desc) }

  def ongoing?
    now = Time.current
    start_time <= now && end_time > now
  end

  def past?
    end_time < Time.current
  end

  def future?
    start_time > Time.current
  end

  def has_content?
    notes.present? || action_items.any?
  end

  def duration_minutes
    ((end_time - start_time) / 60).to_i
  end
end
