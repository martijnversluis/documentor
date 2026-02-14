class WastePickup < ApplicationRecord
  validates :collection_date, presence: true
  validates :waste_type, presence: true
  validates :waste_type, uniqueness: { scope: :collection_date }

  scope :upcoming, -> { where("collection_date >= ?", Date.current).order(:collection_date) }
  scope :for_date, ->(date) { where(collection_date: date) }
  scope :tomorrow, -> { for_date(Date.tomorrow) }
end
