class ReviewStep < ApplicationRecord
  STATUSES = %w[pending skipped completed].freeze

  belongs_to :review, inverse_of: :review_steps
  belongs_to :review_template_step, optional: true

  validates :title, presence: true
  validates :position, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :skipped, -> { where(status: "skipped") }
  scope :done, -> { where(status: %w[completed skipped]) }

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end

  def skipped?
    status == "skipped"
  end

  def complete!(notes_text = nil)
    update!(
      status: "completed",
      completed_at: Time.current,
      notes: notes_text.presence || notes
    )
    review.advance_to_next_step!
  end

  def skip!(notes_text = nil)
    update!(
      status: "skipped",
      completed_at: Time.current,
      notes: notes_text.presence || notes
    )
    review.advance_to_next_step!
  end

  def save_notes!(notes_text)
    update!(notes: notes_text)
  end
end
