module Inbox
  class ActionItemsController < ApplicationController
    def create
      @action_item = ActionItem.new(action_item_params)

      # Apply inbox rules to auto-assign dossier
      if @action_item.dossier_id.blank?
        matching_dossier = InboxRule.find_matching_dossier(@action_item.description)
        @action_item.dossier = matching_dossier if matching_dossier
      end

      if @action_item.save
        respond_to do |format|
          format.html { redirect_to inbox_path, notice: "Actiepunt toegevoegd aan inbox" }
          format.turbo_stream
        end
      else
        redirect_to inbox_path, alert: @action_item.errors.full_messages.join(", ")
      end
    end

    private

    def action_item_params
      params.require(:action_item).permit(:description, :due_date, :recurrence, :notes)
    end
  end
end
