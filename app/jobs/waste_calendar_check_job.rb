class WasteCalendarCheckJob < ApplicationJob
  queue_as :default

  WASTE_TYPE_DESCRIPTIONS = {
    "Restafval" => "Grijze kliko aan de weg zetten",
    "REST" => "Grijze kliko aan de weg zetten",
    "GREY" => "Grijze kliko aan de weg zetten",
    "GFT" => "Groene kliko aan de weg zetten",
    "GREEN" => "Groene kliko aan de weg zetten",
    "Papier" => "Blauwe kliko aan de weg zetten",
    "PAPIER" => "Blauwe kliko aan de weg zetten",
    "PAPER" => "Blauwe kliko aan de weg zetten",
    "PMD" => "PMD kliko aan de weg zetten",
    "PACKAGES" => "PMD kliko aan de weg zetten",
    "Plastic" => "PMD kliko aan de weg zetten",
    "GLAS" => "Glasbak legen",
    "TEXTIEL" => "Textiel naar de container brengen",
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

    return if ActionItem.exists?(description:, due_date: Date.current, completed_at: nil)

    ActionItem.create!(
      description:,
      due_date: Date.current,
      position: 0,
      notes: "waste_type:#{waste_type}",
    )

    Rails.logger.info "Created waste calendar action item: #{description}"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create waste calendar action item for #{waste_type}: #{e.message}"
  end
end
