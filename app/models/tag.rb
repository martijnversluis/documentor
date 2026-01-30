class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:name) }

  def tagged_items
    {
      dossiers: Dossier.joins(:taggings).where(taggings: { tag_id: id }),
      folders: Folder.joins(:taggings).where(taggings: { tag_id: id }),
      documents: Document.joins(:taggings).where(taggings: { tag_id: id }),
      notes: Note.joins(:taggings).where(taggings: { tag_id: id }),
    }
  end
end
