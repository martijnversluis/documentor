module Inbox
  class NotesController < ApplicationController
    def new
      @note = Note.new
    end

    def create
      @note = Note.new(note_params)

      if @note.save
        respond_to do |format|
          format.html { redirect_to inbox_path, notice: "Notitie toegevoegd aan inbox" }
          format.turbo_stream { head :ok }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def note_params
      params.require(:note).permit(:title, :content, :occurred_at)
    end
  end
end
