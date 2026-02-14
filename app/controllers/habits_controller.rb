class HabitsController < ApplicationController
  before_action :set_habit, only: [:edit, :update, :archive, :unarchive, :toggle, :increment, :decrement]

  def index
    @habits = Habit.active.not_archived.ordered.includes(:habit_completions)
    @archived_habits = Habit.archived.ordered
    @date = Date.current
    @week_start = params[:week].present? ? Date.parse(params[:week]).beginning_of_week : Date.current.beginning_of_week
  end

  def new
    @habit = Habit.new
  end

  def create
    @habit = Habit.new(habit_params)

    if @habit.save
      redirect_to habits_path, notice: "Gewoonte aangemaakt"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @habit.update(habit_params)
      redirect_to habits_path, notice: "Gewoonte bijgewerkt"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def archive
    @habit.archive!
    redirect_to habits_path, notice: "Gewoonte gearchiveerd"
  end

  def unarchive
    @habit.unarchive!
    redirect_to habits_path, notice: "Gewoonte hersteld"
  end

  def toggle
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @habit.toggle_completion!(date)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "habit_#{@habit.id}_date_#{date}",
          partial: "habits/habit_checkbox",
          locals: { habit: @habit, date: date }
        )
      end
      format.html { redirect_back fallback_location: habits_path }
    end
  end

  def increment
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @habit.increment_completion!(date)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "habit_#{@habit.id}_date_#{date}",
          partial: "habits/habit_checkbox",
          locals: { habit: @habit, date: date }
        )
      end
      format.html { redirect_back fallback_location: habits_path }
    end
  end

  def decrement
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @habit.decrement_completion!(date)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "habit_#{@habit.id}_date_#{date}",
          partial: "habits/habit_checkbox",
          locals: { habit: @habit, date: date }
        )
      end
      format.html { redirect_back fallback_location: habits_path }
    end
  end

  private

  def set_habit
    @habit = Habit.find(params[:id])
  end

  def habit_params
    params.require(:habit).permit(:name, :description, :frequency, :color, :active, :position, :duration_seconds, :target_count, target_days: [])
  end
end
