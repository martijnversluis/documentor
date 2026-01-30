class ReviewTemplate < ApplicationRecord
  REVIEW_TYPES = %w[daily_start daily_end weekly monthly quarterly yearly].freeze
  REVIEW_TYPE_LABELS = {
    "daily_start" => "Dag start",
    "daily_end" => "Dag eind",
    "weekly" => "Wekelijks",
    "monthly" => "Maandelijks",
    "quarterly" => "Per kwartaal",
    "yearly" => "Jaarlijks"
  }.freeze

  has_many :review_template_steps, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :review_template

  validates :review_type, presence: true, inclusion: { in: REVIEW_TYPES }
  validates :name, presence: true

  accepts_nested_attributes_for :review_template_steps, allow_destroy: true, reject_if: :all_blank

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(review_type: type) }

  def self.active_for_type(type)
    active.by_type(type).first
  end

  def review_type_label
    REVIEW_TYPE_LABELS[review_type]
  end
end
