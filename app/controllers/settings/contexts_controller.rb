module Settings
  class ContextsController < ApplicationController
    before_action :set_context, only: [:edit, :update, :destroy]

    def index
      @contexts = TaskContext.ordered
      @new_context = TaskContext.new
    end

    def create
      @context = TaskContext.new(context_params)
      @context.position = TaskContext.maximum(:position).to_i + 1

      if @context.save
        redirect_to settings_contexts_path, notice: "Context toegevoegd"
      else
        @contexts = TaskContext.ordered
        @new_context = @context
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @context.update(context_params)
        redirect_to settings_contexts_path, notice: "Context bijgewerkt"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @context.destroy!
      redirect_to settings_contexts_path, notice: "Context verwijderd"
    end

    def reorder
      params[:ids].each_with_index do |id, index|
        TaskContext.where(id: id).update_all(position: index)
      end
      head :ok
    end

    private

    def set_context
      @context = TaskContext.find(params[:id])
    end

    def context_params
      params.require(:task_context).permit(:name)
    end
  end
end
