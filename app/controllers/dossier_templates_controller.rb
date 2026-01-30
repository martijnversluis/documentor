class DossierTemplatesController < ApplicationController
  before_action :set_dossier_template, only: [:show, :edit, :update, :destroy, :use]

  def index
    @dossier_templates = DossierTemplate.order(:name)
  end

  def show
  end

  def new
    @dossier_template = DossierTemplate.new
    if params[:from_dossier_id].present?
      @source_dossier = Dossier.find(params[:from_dossier_id])
      @dossier_template.name = "#{@source_dossier.name} template"
      @dossier_template.folders_data = @source_dossier.folders.order(:position).map { |f| { "name" => f.name } }
      @dossier_template.action_items_data = @source_dossier.action_items.pending.map do |item|
        {
          "description" => item.description,
          "context" => item.context,
          "recurrence" => item.recurrence,
          "estimated_minutes" => item.estimated_minutes
        }.compact
      end
    end
  end

  def create
    @dossier_template = DossierTemplate.new(dossier_template_params)

    if @dossier_template.save
      redirect_to dossier_templates_path, notice: "Template aangemaakt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @dossier_template.update(dossier_template_params)
      redirect_to dossier_templates_path, notice: "Template bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @dossier_template.destroy!
    redirect_to dossier_templates_path, notice: "Template verwijderd"
  end

  def use
    @dossier = Dossier.new
  end

  def apply
    @dossier_template = DossierTemplate.find(params[:id])
    @dossier = Dossier.new(dossier_params)

    if @dossier.save
      @dossier_template.apply_to(@dossier)
      redirect_to @dossier, notice: "Dossier aangemaakt vanuit template"
    else
      render :use, status: :unprocessable_entity
    end
  end

  private

  def set_dossier_template
    @dossier_template = DossierTemplate.find(params[:id])
  end

  def dossier_template_params
    params.require(:dossier_template).permit(:name, :description, folders_data: [:name], action_items_data: [:description, :context, :recurrence, :estimated_minutes])
  end

  def dossier_params
    params.require(:dossier).permit(:name, :description)
  end
end
