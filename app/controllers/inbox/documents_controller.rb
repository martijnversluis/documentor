module Inbox
  class DocumentsController < ApplicationController
    def new
      @document = Document.new
    end

    def create
      @document = Document.new(document_params)

      if @document.save
        respond_to do |format|
          format.html { redirect_to inbox_path, notice: "Document toegevoegd aan inbox" }
          format.turbo_stream { head :ok }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def document_params
      params.require(:document).permit(:name, :file, :occurred_at, :remarks)
    end
  end
end
