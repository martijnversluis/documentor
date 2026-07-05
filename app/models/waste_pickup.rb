class WastePickup < ApplicationRecord
  ACTION_ITEM_NOTES_PREFIX = "waste_pickup:".freeze

  WASTE_TYPE_DESCRIPTIONS = {
    "Restafval" => "Grijze kliko aan de weg zetten",
    "REST" => "Grijze kliko aan de weg zetten",
    "GREY" => "Grijze kliko aan de weg zetten",
    "GFT" => "Groene kliko aan de weg zetten",
    "GREEN" => "Groene kliko aan de weg zetten",
    "Papier" => "Blauwe kliko aan de weg zetten",
    "PAPIER" => "Blauwe kliko aan de weg zetten",
    "PAPER" => "Blauwe kliko aan de weg zetten",
    "PMD" => "PMD kliko aan de weg zetten",
    "PACKAGES" => "PMD kliko aan de weg zetten",
    "Plastic" => "PMD kliko aan de weg zetten",
    "GLAS" => "Glasbak legen",
    "TEXTIEL" => "Textiel naar de container brengen"
  }.freeze

  validates :collection_date, presence: true
  validates :waste_type, presence: true
  validates :waste_type, uniqueness: { scope: :collection_date }

  scope :upcoming, -> { where("collection_date >= ?", Date.current).order(:collection_date) }
  scope :for_date, ->(date) { where(collection_date: date) }
  scope :tomorrow, -> { for_date(Date.tomorrow) }

  after_commit :ensure_action_item, on: [:create, :update]
  after_commit :remove_pending_action_item, on: :destroy

  def action_item_description
    WASTE_TYPE_DESCRIPTIONS[waste_type] || "#{waste_type} aan de weg zetten"
  end

  def action_item_notes
    "waste_type:#{waste_type}\n#{ACTION_ITEM_NOTES_PREFIX}#{id}"
  end

  def linked_action_items
    ActionItem.where("notes LIKE ?", "%#{ACTION_ITEM_NOTES_PREFIX}#{id}")
  end

  private

  def ensure_action_item
    item = linked_action_items.first_or_initialize
    item.description = action_item_description
    item.due_date = collection_date - 1.day
    item.notes = action_item_notes
    item.position ||= 0
    item.save! if item.new_record? || item.changed?
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to sync action item for WastePickup #{id}: #{e.message}"
  end

  def remove_pending_action_item
    linked_action_items.where(completed_at: nil).delete_all
  end
end
