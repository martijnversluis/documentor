class Party < ApplicationRecord
  include Taggable

  has_many :party_links, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalizes :name, with: ->(name) { name.strip }

  scope :ordered, -> { order(:name) }

  def linked_items
    {
      dossiers: Dossier.joins(:party_links).where(party_links: { party_id: id }),
      folders: Folder.joins(:party_links).where(party_links: { party_id: id }),
      documents: Document.joins(:party_links).where(party_links: { party_id: id }),
      notes: Note.joins(:party_links).where(party_links: { party_id: id }),
    }
  end
end
