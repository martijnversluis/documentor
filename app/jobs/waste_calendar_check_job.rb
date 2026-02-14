class WasteCalendarCheckJob < ApplicationJob
  queue_as :default

  WASTE_TYPE_DESCRIPTIONS = {
    "Restafval" => "Grijze kliko aan de weg zetten",
    "REST" => "Grijze kliko aan de weg zetten",
    "GREY" => "Grijze kliko aan de weg zetten",
    "GFT" => "Groene kliko aan de weg zetten",
    "GREEN" => "Groene kliko aan de weg zetten",
    "Papier" => "Blauwe kliko aan de weg zetten",
    "PAPER" => "Blauwe kliko aan de weg zetten",
    "PMD" => "PMD kliko aan de weg zetten",
    "PACKAGES" => "PMD kliko aan de weg zetten",
    "Plastic" => "PMD kliko aan de weg zetten"
  }.freeze

  def perform
    service = WasteCalendarService.new
    return unless service.configured?

    tomorrows_pickups = service.tomorrows_pickups
    return if tomorrows_pickups.empty?

    tomorrows_pickups.each do |pickup|
      create_action_item_for_pickup(pickup)
    end
  end

  private

  def create_action_item_for_pickup(pickup)
    waste_type = pickup[:waste_type]
    description = WASTE_TYPE_DESCRIPTIONS[waste_type] || "#{waste_type} aan de weg zetten"

    # Check for existing action item to avoid duplicates
    existing = ActionItem.where(description: description)
                         .where(due_date: Date.current)
                         .where(completed_at: nil)
                         .exists?
    return if existing

    ActionItem.create!(
      description: description,
      due_date: Date.current,
      context: "thuis",
      position: 0,
      notes: "waste_type:#{waste_type}"
    )

    Rails.logger.info "Created waste calendar action item: #{description}"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create waste calendar action item: #{e.message}"
  end
end
