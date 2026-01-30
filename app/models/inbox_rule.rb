class InboxRule < ApplicationRecord
  belongs_to :dossier

  validates :term, presence: true, uniqueness: { case_sensitive: false }
  validates :dossier, presence: true

  scope :ordered, -> { order(:term) }

  def self.find_matching_dossier(description)
    return nil if description.blank?

    rule = all.find { |r| description.downcase.include?(r.term.downcase) }
    rule&.dossier
  end

  def matches?(text)
    return false if text.blank?
    text.downcase.include?(term.downcase)
  end
end
