class ReviewTemplatesController < ApplicationController
  before_action :set_review_template, only: [:show, :edit, :update, :destroy]

  def index
    @review_templates = ReviewTemplate.includes(:review_template_steps)
                                      .order(:review_type, active: :desc, name: :asc)
    @templates_by_type = @review_templates.group_by(&:review_type)
  end

  def show
  end

  def new
    @review_template = ReviewTemplate.new
    @review_template.review_type = params[:review_type] if params[:review_type].present?
  end

  def create
    @review_template = ReviewTemplate.new(review_template_params)

    if @review_template.save
      redirect_to review_templates_path, notice: "Review template aangemaakt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @review_template.update(review_template_params)
      redirect_to review_templates_path, notice: "Review template bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review_template.destroy!
    redirect_to review_templates_path, notice: "Review template verwijderd"
  end

  private

  def set_review_template
    @review_template = ReviewTemplate.find(params[:id])
  end

  def review_template_params
    params.require(:review_template).permit(
      :name, :description, :review_type, :active,
      review_template_steps_attributes: [:id, :title, :description, :position, :_destroy]
    )
  end
end
