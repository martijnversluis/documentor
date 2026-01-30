class DocumentsController < ApplicationController
  before_action :set_parent, only: [:new, :create]
  before_action :set_document, only: [:show, :edit, :update, :destroy, :move, :assign, :download]

  def show
  end

  def new
    @document = build_document
  end

  def create
    @document = build_document(document_params)

    if @document.save
      redirect_to parent_path, notice: "Document toegevoegd"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    update_params = document_params
    # Clear folder_id when moving to a different dossier
    # But not if the document is in a folder and we're just keeping it in the same dossier
    current_dossier_id = @document.folder&.dossier_id || @document.dossier_id
    if update_params[:dossier_id].present? && update_params[:dossier_id].to_i != current_dossier_id
      update_params = update_params.merge(folder_id: nil)
    elsif @document.folder_id.present?
      # Keep the folder_id if we're not moving to a different dossier
      update_params = update_params.except(:dossier_id)
    end

    if @document.update(update_params)
      redirect_to parent_path(@document), notice: "Document bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    dossier = @document.folder&.dossier || @document.dossier
    @document.destroy!

    redirect_to dossier || inbox_path, notice: "Document verwijderd"
  end

  def move
    if params[:folder_id].present?
      @document.update(folder_id: params[:folder_id], dossier_id: nil)
    elsif params[:dossier_id].present?
      @document.update(dossier_id: params[:dossier_id], folder_id: nil)
    end

    head :ok
  end

  def assign
    @document.update(dossier_id: params[:dossier_id], folder_id: nil)
    redirect_to inbox_path, notice: "Document toegewezen aan dossier"
  end

  def download
    if @document.file.attached?
      data = @document.file.download
      extension = File.extname(@document.file.filename.to_s)
      filename = @document.name.end_with?(extension) ? @document.name : "#{@document.name}#{extension}"

      response.headers["Content-Length"] = data.bytesize.to_s
      response.headers["Connection"] = "close"

      send_data data,
                filename: filename,
                type: @document.file.content_type,
                disposition: "attachment"
    else
      redirect_to @document, alert: "Geen bestand beschikbaar"
    end
  end

  private

  def set_parent
    if params[:dossier_id]
      @dossier = Dossier.find(params[:dossier_id])
    elsif params[:folder_id]
      @folder = Folder.find(params[:folder_id])
    end
  end

  def set_document
    @document = Document.find(params[:id])
  end

  def build_document(attrs = {})
    if @dossier
      @dossier.documents.build(attrs)
    else
      @folder.documents.build(attrs)
    end
  end

  def parent_path(doc = @document)
    doc.folder&.dossier || doc.dossier
  end

  def document_params
    params.require(:document).permit(:name, :file, :occurred_at, :tag_list, :remarks, :dossier_id, :expires_at, :expiration_description)
  end
end
