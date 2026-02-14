class Party < ApplicationRecord
  include Taggable

  has_many :party_links, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalizes :name, with: ->(name) { name.strip }

  scope :ordered, -> { order(:name) }

  def linked_items
    linked_folders = Folder.joins(:party_links).where(party_links: { party_id: id })
    direct_documents = Document.joins(:party_links).where(party_links: { party_id: id })
    folder_documents = Document.where(folder_id: linked_folders.select(:id))
                               .where.not(id: direct_documents.select(:id))

    {
      dossiers: Dossier.joins(:party_links).where(party_links: { party_id: id }),
      folders: linked_folders,
      direct_documents: direct_documents,
      folder_documents: folder_documents.includes(:folder),
      notes: Note.joins(:party_links).where(party_links: { party_id: id }),
    }
  end
end
