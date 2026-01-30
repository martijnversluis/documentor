class Dossier < ApplicationRecord
  include PgSearch::Model
  include Taggable
  include PartyLinkable

  pg_search_scope :search,
    against: [:name, :description],
    associated_against: {
      tags: [:name],
      parties: [:name]
    },
    using: {
      tsearch: { prefix: true }
    }

  has_many :folders, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :dossier
  has_many :documents, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :action_items, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :work, -> { where(work_dossier: true) }
  scope :personal, -> { where(work_dossier: false) }
  scope :ordered_by_name, -> { all.sort_by { |d| d.name_without_emoji.downcase } }

  def name_without_emoji
    name.gsub(/[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1F000}-\u{1F02F}\u{1F0A0}-\u{1F0FF}]/, "").strip
  end

  def all_action_items_completed?
    action_items.any? && action_items.pending.none?
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def timeline_items
    all_documents = documents.to_a + folders.flat_map(&:documents)
    all_notes = notes.to_a + folders.flat_map(&:notes)
    (all_documents + all_notes).sort_by(&:display_date).reverse
  end
end
