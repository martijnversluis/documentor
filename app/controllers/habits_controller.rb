class HabitsController < ApplicationController
  before_action :set_habit, only: [:edit, :update, :archive, :unarchive, :toggle, :increment, :decrement, :set_choice]

  def index
    @habits = Habit.active.not_archived.includes(:habit_completions)
      .sort_by { |h| [h.simple_checkbox? ? 1 : 0, h.name.downcase] }
    @archived_habits = Habit.archived.ordered
    @date = Date.current
    @week_start = params[:week].present? ? Date.parse(params[:week]).beginning_of_week : Date.current.beginning_of_week
  end

  def trends
    @days = [30, 90, 180, 365].include?(params[:days].to_i) ? params[:days].to_i : 90
    @end_date = Date.current
    @start_date = @end_date - (@days - 1).days

    @habits = Habit.active.not_archived.includes(:habit_completions).ordered.to_a

    @grid = @habits.each_with_object({}) do |habit, memo|
      completions_by_date = habit.habit_completions.each_with_object({}) do |c, h|
        h[c.completed_on] = c if c.completed_on.between?(@start_date, @end_date)
      end

      created_date = habit.created_at.to_date
      memo[habit.id] = (@start_date..@end_date).each_with_object({}) do |date, dh|
        dh[date] = if date < created_date || !habit.scheduled_for?(date)
                     :not_scheduled
                   else
                     classify_cell(habit, completions_by_date[date])
                   end
      end
    end

    @stats = @habits.each_with_object({}) do |habit, memo|
      states = @grid[habit.id].values
      scheduled = states.count { |v| v != :not_scheduled }
      done = states.count { |v| v == :done }
      memo[habit.id] = {
        scheduled: scheduled,
        done: done,
        percentage: scheduled.positive? ? (done * 100.0 / scheduled).round : 0,
        streak: habit.current_streak
      }
    end

    @daily_totals = (@start_date..@end_date).map do |date|
      scheduled = @habits.count { |h| @grid[h.id][date] != :not_scheduled }
      done = @habits.count { |h| @grid[h.id][date] == :done }
      {
        date: date,
        scheduled: scheduled,
        done: done,
        percentage: scheduled.positive? ? (done * 100.0 / scheduled).round : nil
      }
    end
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

  def set_choice
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @habit.set_choice!(date, params[:choice_value])

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

  def classify_cell(habit, completion)
    return :missed if completion.nil?

    if habit.counter_mode?
      if completion.count >= habit.target_count
        :done
      elsif completion.count.positive?
        :partial
      else
        :missed
      end
    elsif habit.choice_mode?
      completion.choice_value.present? ? :done : :missed
    else
      completion.count >= 1 ? :done : :missed
    end
  end

  def set_habit
    @habit = Habit.find(params[:id])
  end

  def habit_params
    params.require(:habit).permit(:name, :description, :frequency, :color, :active, :position, :duration_seconds, :target_count, :choice_options_text, target_days: [])
  end
end
