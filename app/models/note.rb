class Note < ApplicationRecord
  include PgSearch::Model
  include Taggable
  include PartyLinkable

  pg_search_scope :search,
    against: [:title, :content],
    associated_against: {
      tags: [:name],
      parties: [:name],
      folder: [:name]
    },
    using: {
      tsearch: { prefix: true }
    }

  belongs_to :dossier, optional: true, touch: true
  belongs_to :folder, optional: true, touch: true

  validates :title, presence: true

  scope :inbox, -> { where(dossier_id: nil, folder_id: nil) }
  scope :assigned, -> { where.not(dossier_id: nil).or(where.not(folder_id: nil)) }

  def display_date
    occurred_at || created_at
  end
end
