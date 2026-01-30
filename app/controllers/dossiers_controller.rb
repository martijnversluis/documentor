class DossiersController < ApplicationController
  before_action :set_dossier, only: [:show, :edit, :update, :destroy, :archive, :unarchive, :merge_into]

  def index
    @dossiers = filtered_dossiers(Dossier.active).ordered_by_name
  end

  def archived
    @dossiers = Dossier.archived.order(archived_at: :desc)
  end

  def show
    @folders = @dossier.folders.includes(documents: [:tags, :parties], notes: [:tags, :parties])
    @direct_documents = @dossier.documents.includes(:tags, :parties).where(folder_id: nil)
    @direct_notes = @dossier.notes.includes(:tags, :parties).where(folder_id: nil)
  end

  def new
    @dossier = Dossier.new
  end

  def create
    @dossier = Dossier.new(dossier_params)

    if @dossier.save
      redirect_to @dossier, notice: "Dossier aangemaakt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @dossier.update(dossier_params)
      redirect_to @dossier, notice: "Dossier bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dossier.destroy
    redirect_to dossiers_path, notice: "Dossier verwijderd"
  end

  def archive
    @dossier.archive!
    redirect_to dossiers_path, notice: "Dossier gearchiveerd"
  end

  def unarchive
    @dossier.unarchive!
    redirect_to @dossier, notice: "Dossier hersteld uit archief"
  end

  def merge_into
    target = Dossier.find(params[:target_id])
    source_folder_name = @dossier.name_without_emoji

    # Create main folder for source dossier content
    main_folder = target.folders.create!(name: source_folder_name)

    # Move root documents and notes to the new folder
    @dossier.documents.where(folder_id: nil).update_all(dossier_id: target.id, folder_id: main_folder.id)
    @dossier.notes.where(folder_id: nil).update_all(dossier_id: target.id, folder_id: main_folder.id)

    # Process existing folders from source
    @dossier.folders.each do |folder|
      # Create new folder with prefix (without emoji)
      new_folder = target.folders.create!(name: "#{source_folder_name} / #{folder.name}")

      # Move documents and notes to the new folder
      folder.documents.update_all(dossier_id: target.id, folder_id: new_folder.id)
      folder.notes.update_all(dossier_id: target.id, folder_id: new_folder.id)
    end

    # Move action items to target dossier
    @dossier.action_items.update_all(dossier_id: target.id)

    # Delete the source dossier (folders will be empty now)
    source_name = @dossier.name
    @dossier.destroy!

    respond_to do |format|
      format.html { redirect_to dossiers_path, notice: "#{source_name} samengevoegd met #{target.name}" }
      format.json { head :ok }
    end
  end

  private

  def set_dossier
    @dossier = Dossier.find(params[:id])
  end

  def dossier_params
    params.require(:dossier).permit(:name, :description, :work_dossier)
  end
end
