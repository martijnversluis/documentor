class Checklist < ApplicationRecord
  include Archivable

  # Prevent accidental deletion - checklists should only be archived
  before_destroy :prevent_destruction

  has_many :checklist_items, -> { order(:position) }, dependent: :destroy
  accepts_nested_attributes_for :checklist_items, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  def create_action_items!(dossier: nil, due_date: nil)
    checklist_items.map do |item|
      ActionItem.create!(
        description: item.description,
        dossier: dossier,
        due_date: due_date || Date.current,
        notes: "checklist:#{id}"
      )
    end
  end


  def items_by_section
    # Sort sections: empty section first, then alphabetically
    grouped = checklist_items.order(:position).group_by { |item| item.section.presence || "" }
    grouped.sort_by { |section, _| section.empty? ? "" : section }.to_h
  end

  private

  def prevent_destruction
    errors.add(:base, "Checklists kunnen niet verwijderd worden, alleen gearchiveerd")
    throw(:abort)
  end
end
