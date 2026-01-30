class FoldersController < ApplicationController
  before_action :set_dossier, only: [:new, :create]
  before_action :set_folder, only: [:show, :edit, :update, :destroy, :download]

  def show
  end

  def download
    return redirect_to @folder, alert: "Map is leeg" if @folder.documents.empty?

    zip_data = create_zip_from_folder(@folder)
    filename = "#{@folder.name.parameterize}-#{Date.current}.zip"

    send_data zip_data, filename: filename, type: "application/zip"
  end

  def new
    @folder = @dossier.folders.build
  end

  def create
    @folder = @dossier.folders.build(folder_params)

    if @folder.save
      redirect_to @dossier, notice: "Map aangemaakt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @folder.update(folder_params)
      redirect_to @folder.dossier, notice: "Map bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    dossier = @folder.dossier
    @folder.destroy!

    redirect_to dossier, notice: "Map verwijderd"
  end

  private

  def set_dossier
    @dossier = Dossier.find(params[:dossier_id])
  end

  def set_folder
    @folder = Folder.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name, :position)
  end

  def create_zip_from_folder(folder)
    require "zip"

    Zip::OutputStream.write_buffer do |zip|
      folder.documents.each do |document|
        next unless document.file.attached?

        zip.put_next_entry(document.file.filename.to_s)
        zip.write(document.file.download)
      end
    end.string
  end
end
