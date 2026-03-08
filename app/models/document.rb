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
  has_many :subscription_documents, dependent: :destroy
  has_many :subscriptions, through: :subscription_documents

  has_one_attached :file

  default_scope { order(Arel.sql("COALESCE(documents.occurred_at, documents.created_at) DESC")) }

  validates :name, presence: true

  scope :inbox, -> { where(dossier_id: nil, folder_id: nil) }
  scope :assigned, -> { where.not(dossier_id: nil).or(where.not(folder_id: nil)) }
  scope :without_subscriptions, -> { where.not(id: SubscriptionDocument.select(:document_id)) }

  before_validation :set_name_from_file
  before_validation :extract_date_from_eml
  after_commit :extract_text_content, on: [:create, :update], if: :file_attachment_changed?

  def self.find_duplicate(document)
    return nil unless document.file.attached?

    Document.joins(file_attachment: :blob)
      .where(active_storage_blobs: { checksum: document.file.blob.checksum })
      .where.not(id: document.id)
      .first
  end

  def display_date
    occurred_at || created_at
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

  def extract_text_content
    ExtractDocumentTextJob.perform_later(id)
  end

  def file_attachment_changed?
    return false unless file.attached?

    # Check if file was just attached or changed
    saved_change_to_attribute?(:id) || file.blob.created_at > 5.seconds.ago
  end
end
