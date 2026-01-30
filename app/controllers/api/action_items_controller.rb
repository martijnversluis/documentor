module Api
  class ActionItemsController < BaseController
    def create
      dossier = Dossier.find(params[:dossier_id])
      action_item = dossier.action_items.build(action_item_params)

      if action_item.save
        render json: {
          success: true,
          action_item: {
            id: action_item.id,
            description: action_item.description,
            dossier_id: action_item.dossier_id,
            due_date: action_item.due_date&.iso8601,
            recurrence: action_item.recurrence
          }
        }, status: :created
      else
        render json: {
          success: false,
          errors: action_item.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def action_item_params
      params.permit(:description, :due_date, :recurrence)
    end
  end
end
