module Inbox
  class DocumentsController < ApplicationController
    def new
      @document = Document.new
    end

    def create
      @document = Document.new(document_params)

      if @document.save
        create_action_item_if_requested

        respond_to do |format|
          format.html { redirect_to inbox_path, notice: "Document toegevoegd aan inbox" }
          format.turbo_stream { head :ok }
          format.json { render json: { id: @document.id, name: @document.name } }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def create_action_item_if_requested
      return unless params[:create_action_item] == "1"

      due_date = case params[:due_date]
                 when "today" then Date.current
                 when "tomorrow" then Date.tomorrow
                 else nil
                 end

      ActionItem.create!(
        description: @document.name,
        due_date: due_date,
        notes: "[#{@document.name}](/documents/#{@document.id})"
      )
    end

    def document_params
      params.require(:document).permit(:name, :file, :occurred_at, :remarks)
    end
  end
end
