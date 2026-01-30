class NotesController < ApplicationController
  before_action :set_parent, only: [:new, :create]
  before_action :set_note, only: [:show, :edit, :update, :destroy, :move, :assign]

  def show
  end

  def new
    @note = build_note
  end

  def create
    @note = build_note(note_params)

    if @note.save
      redirect_to parent_path, notice: "Notitie toegevoegd"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    update_params = note_params
    # Clear folder_id when moving to a different dossier
    if update_params[:dossier_id].present? && update_params[:dossier_id].to_i != @note.dossier_id
      update_params = update_params.merge(folder_id: nil)
    end

    if @note.update(update_params)
      redirect_to parent_path(@note), notice: "Notitie bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    dossier = @note.folder&.dossier || @note.dossier
    @note.destroy!

    redirect_to dossier || inbox_path, notice: "Notitie verwijderd"
  end

  def move
    if params[:folder_id].present?
      @note.update(folder_id: params[:folder_id], dossier_id: nil)
    elsif params[:dossier_id].present?
      @note.update(dossier_id: params[:dossier_id], folder_id: nil)
    end

    head :ok
  end

  def assign
    @note.update(dossier_id: params[:dossier_id], folder_id: nil)
    redirect_to inbox_path, notice: "Notitie toegewezen aan dossier"
  end

  private

  def set_parent
    if params[:dossier_id]
      @dossier = Dossier.find(params[:dossier_id])
    elsif params[:folder_id]
      @folder = Folder.find(params[:folder_id])
    end
  end

  def set_note
    @note = Note.find(params[:id])
  end

  def build_note(attrs = {})
    if @dossier
      @dossier.notes.build(attrs)
    else
      @folder.notes.build(attrs)
    end
  end

  def parent_path(note = @note)
    note.folder&.dossier || note.dossier
  end

  def note_params
    params.require(:note).permit(:title, :content, :occurred_at, :dossier_id)
  end
end
