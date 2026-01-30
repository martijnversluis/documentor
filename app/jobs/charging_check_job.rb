class ChargingCheckJob < ApplicationJob
  queue_as :default

  DESCRIPTION = "Auto opladen".freeze

  def perform
    service = ChargingStatusService.new
    status = service.fetch_status

    return if status.nil?

    if status[:needs_charging]
      create_action_item_if_needed(status)
    else
      complete_existing_action_item
    end
  end

  private

  def create_action_item_if_needed(status)
    existing = ActionItem.where(description: DESCRIPTION)
                         .where(completed_at: nil)
                         .exists?
    return if existing

    notes = "charging_status:needs_charging\n" \
            "Actieradius: #{status[:available_range_km]&.round(0)} km\n" \
            "Volgende rit: #{status[:trip_distance_km]&.round(0)} km"

    ActionItem.create!(
      description: DESCRIPTION,
      due_date: Date.current,
      context: "thuis",
      position: 0,
      notes: notes
    )

    Rails.logger.info "Created charging action item"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create charging action item: #{e.message}"
  end

  def complete_existing_action_item
    ActionItem.where(description: DESCRIPTION)
              .where(completed_at: nil)
              .find_each do |item|
      item.update!(completed_at: Time.current)
      Rails.logger.info "Auto-completed charging action item: #{item.id}"
    end
  end
end
