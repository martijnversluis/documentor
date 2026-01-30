class DossierTemplate < ApplicationRecord
  validates :name, presence: true

  def folders_data
    super || []
  end

  def action_items_data
    super || []
  end

  def apply_to(dossier)
    folders_data.each_with_index do |folder_data, index|
      dossier.folders.create!(
        name: folder_data["name"],
        position: index
      )
    end

    action_items_data.each do |item_data|
      dossier.action_items.create!(
        description: item_data["description"],
        context: item_data["context"],
        recurrence: item_data["recurrence"],
        estimated_minutes: item_data["estimated_minutes"]
      )
    end
  end

  def self.create_from_dossier(dossier, name:, description: nil)
    create!(
      name: name,
      description: description,
      folders_data: dossier.folders.order(:position).map { |f| { "name" => f.name } },
      action_items_data: dossier.action_items.pending.map do |item|
        {
          "description" => item.description,
          "context" => item.context,
          "recurrence" => item.recurrence,
          "estimated_minutes" => item.estimated_minutes
        }.compact
      end
    )
  end
end
