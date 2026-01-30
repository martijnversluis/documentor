class ReviewTemplateStep < ApplicationRecord
  belongs_to :review_template, inverse_of: :review_template_steps

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :set_position, on: :create

  private

  def set_position
    return if position.present?
    max_position = review_template.review_template_steps.maximum(:position) || -1
    self.position = max_position + 1
  end
end
