class ChecklistsController < ApplicationController
  before_action :set_checklist, only: [:show, :edit, :update, :destroy, :use]

  def index
    @checklists = Checklist.ordered.includes(:checklist_items)
  end

  def show
  end

  def new
    @checklist = Checklist.new
    @checklist.checklist_items.build
  end

  def create
    @checklist = Checklist.new(checklist_params)

    if @checklist.save
      redirect_to checklists_path, notice: "Checklist aangemaakt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @checklist.checklist_items.build if @checklist.checklist_items.empty?
  end

  def update
    if @checklist.update(checklist_params)
      redirect_to checklists_path, notice: "Checklist bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @checklist.destroy!
    redirect_to checklists_path, notice: "Checklist verwijderd"
  end

  def use
    @dossiers = Dossier.active.ordered
  end

  def apply
    @checklist = Checklist.find(params[:id])
    dossier = params[:dossier_id].present? ? Dossier.find(params[:dossier_id]) : nil
    due_date = params[:due_date].present? ? Date.parse(params[:due_date]) : Date.current

    items = @checklist.create_action_items!(dossier: dossier, due_date: due_date)
    redirect_to action_items_path(today: "1"), notice: "#{items.count} actiepunten aangemaakt vanuit checklist"
  end

  private

  def set_checklist
    @checklist = Checklist.find(params[:id])
  end

  def checklist_params
    params.require(:checklist).permit(
      :name, :description,
      checklist_items_attributes: [:id, :description, :context, :estimated_minutes, :position, :_destroy]
    )
  end
end
