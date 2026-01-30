module Api
  class NotesController < BaseController
    def create
      dossier = Dossier.find(params[:dossier_id])
      note = dossier.notes.build(note_params)

      if note.save
        render json: {
          success: true,
          note: {
            id: note.id,
            title: note.title,
            dossier_id: note.dossier_id
          }
        }, status: :created
      else
        render json: {
          success: false,
          errors: note.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def note_params
      params.permit(:title, :content, :occurred_at)
    end
  end
end
