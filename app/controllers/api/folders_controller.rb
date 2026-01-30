module Api
  class FoldersController < BaseController
    def index
      dossier = Dossier.find(params[:dossier_id])
      folders = dossier.folders.order(:position)

      render json: {
        folders: folders.map { |f| { id: f.id, name: f.name } }
      }
    end
  end
end
