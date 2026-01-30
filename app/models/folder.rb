class Folder < ApplicationRecord
  include Taggable
  include PartyLinkable

  belongs_to :dossier, touch: true

  has_many :documents, dependent: :destroy
  has_many :notes, dependent: :destroy

  acts_as_list scope: :dossier

  validates :name, presence: true

  def timeline_items
    (documents.to_a + notes.to_a).sort_by { |item| item.occurred_at || item.created_at }.reverse
  end
end
