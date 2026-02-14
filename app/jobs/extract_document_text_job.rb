class ExtractDocumentTextJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Document.find_by(id: document_id)
    return unless document&.file&.attached?

    text = TextExtractionService.new(document).extract

    if text.present?
      document.update_column(:content_text, text)
      Rails.logger.info "Extracted #{text.length} characters from document #{document_id}"
    end
  end
end
