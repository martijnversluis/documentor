class ReviewsController < ApplicationController
  before_action :set_review, only: [:show, :start, :pause, :resume, :destroy]

  def index
    @year = (params[:year] || Date.current.year).to_i
    @reviews = Review.for_year(@year).ordered
    @habit_data = build_habit_data(@year)

    # Current period reviews for each type
    @current_reviews = Review::REVIEW_TYPES.map do |type|
      review = Review.find_or_initialize_for_period(type)
      template = ReviewTemplate.active_for_type(type)
      [type, { review: review, template: template }]
    end.to_h
  end

  def show
    @current_step = @review.current_step
  end

  def create
    review_type = params[:review_type]

    unless Review::REVIEW_TYPES.include?(review_type)
      redirect_to reviews_path, alert: "Ongeldig review type"
      return
    end

    @review = Review.find_or_initialize_for_period(review_type)

    if @review.persisted?
      # If already exists but not started, start it
      if @review.pending? && @review.start!
        redirect_to review_path(@review), notice: "Review gestart"
      else
        redirect_to review_path(@review)
      end
    elsif @review.save
      # Automatically start the review after creating
      template = ReviewTemplate.active_for_type(@review.review_type)
      if template.present? && template.review_template_steps.any? && @review.start!
        redirect_to review_path(@review), notice: "Review gestart"
      else
        redirect_to review_path(@review), notice: "Review aangemaakt"
      end
    else
      redirect_to reviews_path, alert: @review.errors.full_messages.join(", ")
    end
  end

  def start
    template = ReviewTemplate.active_for_type(@review.review_type)

    if template.nil? || template.review_template_steps.empty?
      redirect_to reviews_path, alert: "Geen template gevonden voor dit review type. Maak eerst een template aan."
      return
    end

    if @review.start!
      redirect_to review_path(@review), notice: "Review gestart"
    else
      redirect_to review_path(@review), alert: "Kon review niet starten"
    end
  end

  def pause
    @review.pause!
    redirect_to reviews_path, notice: "Review gepauzeerd"
  end

  def resume
    @review.resume!
    redirect_to review_path(@review), notice: "Review hervat"
  end

  def destroy
    @review.destroy!
    redirect_to reviews_path, notice: "Review verwijderd"
  end

  def next_review
    # Find in-progress reviews first
    in_progress = Review.in_progress.order(period_start: :desc).first
    if in_progress
      render json: { review_url: review_path(in_progress) }
      return
    end

    # Find due or due_soon reviews
    Review::REVIEW_TYPES.each do |type|
      review = Review.find_or_initialize_for_period(type)
      if review.persisted? && !review.completed? && (review.due? || review.due_soon?)
        render json: { review_url: review_path(review) }
        return
      elsif !review.persisted? && (review.due? || review.due_soon?)
        # Review doesn't exist yet but should be started
        render json: { review_url: reviews_path(start_type: type) }
        return
      end
    end

    render json: { review_url: nil }
  end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def build_habit_data(year)
    today = Date.current
    year_start = Date.new(year, 1, 1)

    Review::REVIEW_TYPES.map do |type|
      periods = generate_periods_for_type(type, year, today)
      reviews = Review.where(review_type: type).for_year(year).index_by(&:period_key)

      periods_with_status = periods.map do |period|
        review = reviews[period[:key]]
        {
          label: period[:label],
          completed: review&.completed?,
          in_progress: review&.in_progress?,
          future: period[:end_date] > today,
          current: period[:start_date] <= today && period[:end_date] >= today
        }
      end

      # Calculate streak (consecutive completed periods ending at current or last completed)
      streak = calculate_streak(periods_with_status)

      # Count completed vs total (excluding future)
      past_periods = periods_with_status.reject { |p| p[:future] }
      completed_count = past_periods.count { |p| p[:completed] }

      {
        type: type,
        label: Review::REVIEW_TYPE_LABELS[type],
        periods: periods_with_status,
        streak: streak,
        completed_count: completed_count,
        total_count: past_periods.count
      }
    end
  end

  def generate_periods_for_type(type, year, today)
    periods = []
    year_start = Date.new(year, 1, 1)
    year_end = Date.new(year, 12, 31)

    case type
    when "daily_start", "daily_end"
      # Show last 30 days for daily reviews
      start_date = [year_start, today - 29.days].max
      end_date = [year_end, today].min
      (start_date..end_date).each do |date|
        suffix = type == "daily_start" ? "-start" : "-end"
        periods << {
          key: "#{date.strftime('%Y-%m-%d')}#{suffix}",
          label: date.strftime("%d %b"),
          start_date: date,
          end_date: date
        }
      end
    when "weekly"
      # Show all weeks in the year
      current = year_start.beginning_of_week
      while current <= year_end
        week_end = current.end_of_week
        periods << {
          key: "#{current.cwyear}-W#{current.strftime('%V')}",
          label: "Week #{current.strftime('%V')}",
          start_date: current,
          end_date: week_end
        }
        current += 1.week
      end
    when "monthly"
      # Show all months in the year
      (1..12).each do |month|
        date = Date.new(year, month, 1)
        periods << {
          key: date.strftime("%Y-%m"),
          label: I18n.l(date, format: "%b"),
          start_date: date,
          end_date: date.end_of_month
        }
      end
    when "quarterly"
      # Show all quarters in the year
      [1, 4, 7, 10].each_with_index do |month, i|
        date = Date.new(year, month, 1)
        periods << {
          key: "#{year}-Q#{i + 1}",
          label: "Q#{i + 1}",
          start_date: date,
          end_date: (date + 2.months).end_of_month
        }
      end
    when "yearly"
      # Just this year
      periods << {
        key: year.to_s,
        label: year.to_s,
        start_date: year_start,
        end_date: year_end
      }
    end

    periods
  end

  def calculate_streak(periods_with_status)
    # Find current or most recent non-future period
    relevant_periods = periods_with_status.reject { |p| p[:future] }.reverse

    streak = 0
    relevant_periods.each do |period|
      if period[:completed]
        streak += 1
      else
        break
      end
    end

    streak
  end
end
