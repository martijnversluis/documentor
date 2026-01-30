class ExpirationCheckJob < ApplicationJob
  queue_as :default

  def perform
    check_expiring_documents
    check_expired_documents
    check_expiring_items
    check_expired_items
  end

  private

  # === Documents ===

  def check_expiring_documents
    Document.expiring_soon.find_each do |document|
      create_document_warning(document, expired: false)
    end
  end

  def check_expired_documents
    Document.expired.find_each do |document|
      create_document_warning(document, expired: true)
    end
  end

  def create_document_warning(document, expired:)
    description = expired ? "**#{document.name}** is verlopen" : "**#{document.name}** verloopt binnenkort"

    return if action_item_exists?(description)

    notes = build_document_notes(document)

    ActionItem.create!(
      description: description,
      due_date: expired ? Date.current : document.expires_at,
      dossier: document.dossier,
      notes: notes,
      position: expired ? 0 : 1
    )

    Rails.logger.info "Created expiration warning for document: #{document.name}"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create document expiration warning: #{e.message}"
  end

  def build_document_notes(document)
    days = document.days_until_expiration
    notes = ["expiration_tracking:document:#{document.id}"]
    notes << format_days_message(days, document.expires_at)
    notes << "" << document.expiration_description if document.expiration_description.present?
    notes.join("\n")
  end

  # === Expiring Items (physical documents) ===

  def check_expiring_items
    ExpiringItem.find_each do |item|
      next unless item.expiring_soon?
      create_item_warning(item, expired: false)
    end
  end

  def check_expired_items
    ExpiringItem.expired.find_each do |item|
      create_item_warning(item, expired: true)
    end
  end

  def create_item_warning(item, expired:)
    description = expired ? "**#{item.name}** is verlopen" : "**#{item.name}** verloopt binnenkort"

    return if action_item_exists?(description)

    notes = build_item_notes(item)

    ActionItem.create!(
      description: description,
      due_date: expired ? Date.current : item.expires_at,
      notes: notes,
      position: expired ? 0 : 1
    )

    Rails.logger.info "Created expiration warning for item: #{item.name}"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create item expiration warning: #{e.message}"
  end

  def build_item_notes(item)
    days = item.days_until_expiration
    notes = ["expiration_tracking:item:#{item.id}"]
    notes << format_days_message(days, item.expires_at)
    notes << "" << item.description if item.description.present?
    notes.join("\n")
  end

  # === Helpers ===

  def format_days_message(days, expires_at)
    if days < 0
      "Verlopen sinds: #{days.abs} dagen geleden"
    elsif days == 0
      "Verloopt: vandaag"
    else
      "Verloopt over: #{days} dagen (#{expires_at.strftime('%d-%m-%Y')})"
    end
  end

  def action_item_exists?(description)
    ActionItem.where(description: description)
              .where(completed_at: nil)
              .exists?
  end
end
