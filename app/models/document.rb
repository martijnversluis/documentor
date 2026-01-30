class Document < ApplicationRecord
  include PgSearch::Model
  include Taggable
  include PartyLinkable

  pg_search_scope :search,
    against: [:name, :content_text, :remarks],
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
  has_many :action_item_documents, dependent: :destroy
  has_many :action_items, through: :action_item_documents

  has_one_attached :file

  default_scope { order(Arel.sql("COALESCE(documents.occurred_at, documents.created_at) DESC")) }

  validates :name, presence: true

  scope :inbox, -> { where(dossier_id: nil, folder_id: nil) }
  scope :assigned, -> { where.not(dossier_id: nil).or(where.not(folder_id: nil)) }
  scope :expiring_soon, ->(days = 30) { where(expires_at: Date.current..days.days.from_now) }
  scope :expired, -> { where("expires_at < ?", Date.current) }
  scope :with_expiration, -> { where.not(expires_at: nil) }

  before_validation :set_name_from_file
  before_validation :extract_date_from_eml

  def display_date
    occurred_at || created_at
  end

  def expired?
    expires_at.present? && expires_at < Date.current
  end

  def expiring_soon?(days = 30)
    expires_at.present? && expires_at >= Date.current && expires_at <= days.days.from_now
  end

  def days_until_expiration
    return nil unless expires_at.present?
    (expires_at - Date.current).to_i
  end

  private

  def set_name_from_file
    return if name.present? || !file.attached?

    self.name = file.filename.to_s
  end

  def extract_date_from_eml
    return if occurred_at.present? || !file.attached?
    return unless file.content_type == "message/rfc822" || file.filename.to_s.end_with?(".eml")

    begin
      content = file.download
      mail = Mail.new(content)
      self.occurred_at = mail.date if mail.date.present?
    rescue => e
      Rails.logger.warn "Could not extract date from EML: #{e.message}"
    end
  end
end
