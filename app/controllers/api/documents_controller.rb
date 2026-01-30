module Api
  class DocumentsController < BaseController
    include Rails.application.routes.url_helpers

    def create
      if params[:folder_id].present?
        folder = Folder.find(params[:folder_id])
        document = folder.documents.build(document_params)
      else
        dossier = Dossier.find(params[:dossier_id])
        document = dossier.documents.build(document_params)
      end

      if document.save
        # Build URL to dossier with document highlight
        dossier = document.dossier || document.folder.dossier
        highlight_params = { highlight: "document_#{document.id}_highlight" }
        highlight_params[:expand_folder] = document.folder_id if document.folder_id

        render json: {
          success: true,
          document: {
            id: document.id,
            name: document.name,
            dossier_id: dossier.id,
            folder_id: document.folder_id,
            url: dossier_url(dossier, highlight_params)
          }
        }, status: :created
      else
        render json: {
          success: false,
          errors: document.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def document_params
      params.permit(:name, :file, :occurred_at, :source_description, :remarks)
    end

    def default_url_options
      { host: request.host, port: request.port }
    end
  end
end
