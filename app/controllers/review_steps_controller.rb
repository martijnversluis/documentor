class ReviewStepsController < ApplicationController
  before_action :set_review
  before_action :set_review_step

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    @review_step.save_notes!(params[:notes])

    respond_to do |format|
      format.html { redirect_to review_path(@review) }
      format.turbo_stream { head :ok }
    end
  end

  def complete
    @review_step.complete!(params[:notes])

    respond_to do |format|
      format.html { redirect_to_next_or_complete }
      format.turbo_stream
    end
  end

  def skip
    @review_step.skip!(params[:notes])

    respond_to do |format|
      format.html { redirect_to_next_or_complete }
      format.turbo_stream
    end
  end

  private

  def set_review
    @review = Review.find(params[:review_id])
  end

  def set_review_step
    @review_step = @review.review_steps.find(params[:id])
  end

  def redirect_to_next_or_complete
    if @review.completed?
      redirect_to review_path(@review), notice: "Review voltooid!"
    else
      redirect_to review_path(@review)
    end
  end
end
