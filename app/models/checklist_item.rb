class ChecklistItem < ApplicationRecord
  belongs_to :checklist

  validates :description, presence: true

  before_create :set_position

  private

  def set_position
    self.position ||= (checklist.checklist_items.maximum(:position) || 0) + 1
  end
end
