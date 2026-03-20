class ExpirationCheckJob < ApplicationJob
  queue_as :default

  def perform
    check_expiring_items
    check_expired_items
  end

  private

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
