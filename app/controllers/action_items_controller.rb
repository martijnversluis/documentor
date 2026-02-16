class ActionItemsController < ApplicationController
  before_action :set_action_item, only: [:show, :edit, :update, :destroy, :toggle, :assign, :update_completion_notes, :update_notes, :extract_notes]
  before_action :load_filter_counts, only: [:today, :tomorrow, :yesterday, :overdue, :waiting, :someday, :next_actions, :quick_wins, :recurring, :inbox]

  def today
    @current_filter = :today
    @filter_label = "vandaag"
    @pending_items = base_pending_scope.today
    @completed_items = recent_completed_items
    @pending_reviews = pending_reviews_for_today
    @calendar_events = load_calendar_events(Date.current)
    @habits = load_habits_for_today
    render :index
  end

  def tomorrow
    @current_filter = :tomorrow
    @filter_label = "morgen"
    @pending_items = base_pending_scope.tomorrow
    @completed_items = recent_completed_items
    @calendar_events = load_calendar_events(Date.tomorrow)
    render :index
  end

  def yesterday
    @current_filter = :yesterday
    @filter_label = "gisteren"
    @pending_items = ActionItem.none
    @completed_items = base_scope.completed_yesterday.root_items.includes(:dossier, :children).order(completed_at: :desc)
    @calendar_events = load_calendar_events(Date.yesterday)
    @show_only_completed = true
    render :index
  end

  def overdue
    @current_filter = :overdue
    @filter_label = "verlopen"
    @pending_items = base_pending_scope.overdue
    @completed_items = recent_completed_items
    render :index
  end

  def waiting
    @current_filter = :waiting
    @filter_label = "wachtend"
    @pending_items = base_pending_scope.waiting
    @completed_items = recent_completed_items
    render :index
  end

  def someday
    @current_filter = :someday
    @filter_label = "ooit/misschien"
    @pending_items = base_scope.pending.root_items.includes(:dossier, :waiting_for_party, :children).someday_maybe.ordered
    @completed_items = recent_completed_items
    render :index
  end

  def next_actions
    @current_filter = :next_actions
    @filter_label = "eerstvolgende"
    @pending_items = base_pending_scope.next_actions
    @completed_items = recent_completed_items
    render :index
  end

  def quick_wins
    @current_filter = :quick_wins
    @filter_label = "quick win"
    @pending_items = base_pending_scope.quick_wins
    @completed_items = recent_completed_items
    render :index
  end

  def recurring
    @current_filter = :recurring
    @filter_label = "herhalend"
    @pending_items = base_pending_scope.recurring
    @completed_items = recent_completed_items
    render :index
  end

  def inbox
    @current_filter = :inbox
    @filter_label = "inbox"
    @pending_items = base_pending_scope.inbox
    @completed_items = recent_completed_items
    render :index
  end

  def week
    today = Date.current

    @start_date = case action_name_from_route
    when "current"
      today.beginning_of_week(:monday)
    when "next"
      today.next_week(:monday)
    when "previous"
      today.prev_week(:monday)
    else
      Date.commercial(today.year, params[:number].to_i, 1)
    end

    @end_date = @start_date + 6.days
    @days = (@start_date..@end_date).to_a
    @week_number = @start_date.cweek
    @prev_week = (@start_date - 7.days).cweek
    @next_week = (@start_date + 7.days).cweek

    @action_items_by_date = filtered_action_items(ActionItem.pending.active)
      .where(due_date: @start_date..@end_date)
      .includes(:dossier)
      .ordered
      .group_by(&:due_date)

    @recurring_items = filtered_action_items(ActionItem.pending.active.recurring)
      .includes(:dossier)
      .ordered

    @calendar_events_by_date = {}
    @days.each { |day| @calendar_events_by_date[day] = [] }

    GoogleAccount.includes(:google_calendars).find_each do |account|
      next unless account.enabled_calendars.any?

      begin
        service = GoogleCalendarService.new(account)
        @days.each do |day|
          events = service.events(date: day)
          @calendar_events_by_date[day].concat(events)
        end
      rescue GoogleCalendarService::TokenRefreshError => e
        Rails.logger.warn "Failed to load calendar events for #{account.email}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Calendar error for #{account.email}: #{e.message}"
      end
    end

    @calendar_events_by_date.each do |day, events|
      events.sort_by! { |e| e[:start_time] || day.beginning_of_day }
    end

    @total_events = @calendar_events_by_date.values.sum(&:size)
    @total_tasks = @action_items_by_date.values.sum(&:size)
  end

  def show
    @recent_documents = Document.where("created_at > ?", 24.hours.ago)
                                .where.not(id: @action_item.document_ids)
                                .order(created_at: :desc)
                                .limit(10)
  end

  def edit
    @return_to = params[:return_to]
  end

  def create
    if params[:dossier_id].present?
      @dossier = Dossier.find(params[:dossier_id])
      @action_item = @dossier.action_items.build(action_item_params)
    else
      @action_item = ActionItem.new(action_item_params)
      apply_filter_defaults
      @from_index = params[:from_index] == "1"

      if @action_item.dossier_id.blank?
        matching_dossier = InboxRule.find_matching_dossier(@action_item.description)
        @action_item.dossier = matching_dossier if matching_dossier
      end
    end

    if @action_item.save
      respond_to do |format|
        redirect_path = if @action_item.parent_id.present?
          action_item_path(@action_item.parent, anchor: "add-sub-item")
        else
          params[:redirect_to].presence || @dossier || today_action_items_path
        end
        format.html { redirect_to redirect_path, notice: "Actiepunt toegevoegd" }
        format.turbo_stream
      end
    else
      redirect_to params[:redirect_to].presence || @dossier || today_action_items_path, alert: @action_item.errors.full_messages.join(", ")
    end
  end

  def update
    if @action_item.update(action_item_params)
      redirect_to params[:return_to].presence || today_action_items_path, notice: "Actiepunt bijgewerkt"
    else
      @return_to = params[:return_to]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @action_item.destroy!

    respond_to do |format|
      format.html { redirect_back fallback_location: today_action_items_path, notice: "Actiepunt verwijderd" }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@action_item) }
    end
  end

  def toggle
    begin
      if @action_item.dossier.present?
        count_before = @action_item.dossier.action_items.count
        @action_item.toggle!
        @new_occurrence = @action_item.dossier.action_items.pending.order(created_at: :desc).first if @action_item.dossier.action_items.count > count_before
      else
        count_before = ActionItem.inbox.count
        @action_item.toggle!
        @new_occurrence = ActionItem.inbox.pending.order(created_at: :desc).first if ActionItem.inbox.count > count_before
      end
      @from_dashboard = request.referer&.include?("dashboard") || request.referer == root_url
      @from_inbox = request.referer&.include?("inbox")
      @from_action_items_index = params[:from] == "index"

      respond_to do |format|
        if params[:redirect_to].present?
          format.html { redirect_to params[:redirect_to] }
        else
          format.html { redirect_back fallback_location: @action_item.dossier || inbox_path }
        end
        format.turbo_stream
      end
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html { redirect_to params[:redirect_to].presence || today_action_items_path, alert: e.record.errors.full_messages.join(", ") }
        format.turbo_stream { render turbo_stream: turbo_stream.append("flash", partial: "shared/flash", locals: { message: e.record.errors.full_messages.join(", "), type: "alert" }) }
      end
    end
  end

  def assign
    @action_item.update(dossier_id: params[:dossier_id])

    respond_to do |format|
      format.html { redirect_to inbox_path, notice: "Actiepunt toegewezen aan dossier" }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@action_item) }
    end
  end

  def update_completion_notes
    @action_item.update(completion_notes: params[:completion_notes])
    render plain: helpers.markdown(@action_item.completion_notes.to_s)
  end

  def update_notes
    @action_item.update(notes: params[:notes])
    render plain: helpers.markdown(@action_item.notes.to_s)
  end

  def extract_notes
    if @action_item.notes.blank?
      redirect_to @action_item, alert: "Geen notities om te extraheren"
      return
    end

    note = Note.new(
      title: @action_item.description.truncate(255),
      content: @action_item.notes,
      dossier: @action_item.dossier,
      occurred_at: Time.current
    )

    if note.save
      @action_item.update!(notes: nil)
      redirect_to note, notice: "Notities verplaatst naar losse notitie"
    else
      redirect_to @action_item, alert: "Kon notities niet verplaatsen: #{note.errors.full_messages.join(', ')}"
    end
  end

  def reorder
    if params[:ids].present?
      params[:ids].each_with_index do |id, index|
        ActionItem.where(id: id).update_all(position: index)
      end
    end
    head :ok
  end

  def postpone_today
    count = filtered_action_items(ActionItem.pending.active.where(due_date: ..Date.current)).update_all(due_date: Date.tomorrow)
    message = count == 1 ? "1 actiepunt doorgeschoven naar morgen" : "#{count} actiepunten doorgeschoven naar morgen"
    redirect_to today_action_items_path, notice: message
  end

  def power_through
    @all_items = filtered_action_items(ActionItem.pending.active.today.root_items).includes(:dossier, :children).ordered.to_a

    if @all_items.empty?
      redirect_to today_action_items_path, notice: "Alle actiepunten voor vandaag zijn afgerond!"
      return
    end

    if params[:item_id].present?
      @current_item = @all_items.find { |i| i.id == params[:item_id].to_i }
    end
    @current_item ||= @all_items.first

    @current_index = @all_items.index(@current_item) || 0
    @total_count = @all_items.count
    @completed_count = filtered_action_items(ActionItem.completed_today).count
  end

  private

  def action_name_from_route
    request.path.split("/week/").last.split("/").first
  end

  def set_action_item
    @action_item = ActionItem.find(params[:id])
  end

  def action_item_params
    params.require(:action_item).permit(:description, :due_date, :recurrence, :context, :dossier_id, :waiting_for_party_id, :waiting_for_description, :someday, :estimated_minutes, :next_action, :parent_id, :notes)
  end

  def base_scope
    filtered_action_items(ActionItem.all)
  end

  def base_pending_scope
    base_scope.pending.active.root_items.includes(:dossier, :waiting_for_party, :children).ordered
  end

  def recent_completed_items
    base_scope.completed.root_items.includes(:dossier, :children).order(completed_at: :desc).limit(20)
  end

  def load_filter_counts
    @today_count = base_scope.pending.active.today.root_items.count
    @tomorrow_count = base_scope.pending.active.tomorrow.root_items.count
    @yesterday_count = base_scope.completed_yesterday.root_items.count
    @overdue_count = base_scope.pending.active.overdue.root_items.count
    @waiting_count = base_scope.pending.active.waiting.root_items.count
    @someday_count = base_scope.pending.someday_maybe.root_items.count
    @quick_count = base_scope.pending.active.quick_wins.root_items.count
    @next_count = base_scope.pending.active.next_actions.root_items.count
    @recurring_count = base_scope.pending.active.recurring.root_items.count
    @inbox_count = base_scope.pending.active.inbox.root_items.count
  end

  def apply_filter_defaults
    # Subitems inherit parent's due_date (or lack thereof)
    if @action_item.parent_id.present?
      parent = ActionItem.find(@action_item.parent_id)
      @action_item.due_date ||= parent.due_date
      return
    end

    case params[:filter]&.to_sym
    when :today
      @action_item.due_date ||= Date.current
    when :tomorrow
      @action_item.due_date ||= Date.tomorrow
    when :someday
      @action_item.someday = true
    when :quick_wins
      @action_item.due_date ||= Date.current
      @action_item.estimated_minutes ||= 15
    when :next_actions
      @action_item.next_action = true
    end

    # Default to today unless specific filters
    @action_item.due_date ||= Date.current unless params[:filter]&.to_sym.in?([:someday, :tomorrow, :inbox])
  end

  def pending_reviews_for_today
    current_hour = Time.current.hour
    weekend = Date.current.wday.in?([0, 6])

    Review::REVIEW_TYPES.filter_map do |type|
      next if type == "daily_start" && (weekend || current_hour >= 12)
      next if type == "daily_end" && (weekend || current_hour < 12)

      review = Review.find_or_initialize_for_period(type)
      template = ReviewTemplate.active_for_type(type)
      next if review.completed? || template.nil?
      next unless review.due? || review.due_soon?

      { type: type, review: review, template: template }
    end
  end

  def load_calendar_events(date)
    events = []

    GoogleAccount.includes(:google_calendars).find_each do |account|
      next unless account.enabled_calendars.any?

      begin
        service = GoogleCalendarService.new(account)
        events.concat(service.events(date: date))
      rescue GoogleCalendarService::TokenRefreshError => e
        Rails.logger.warn "Failed to load calendar events for #{account.email}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Calendar error for #{account.email}: #{e.message}"
      end
    end

    events.sort_by { |e| e[:start_time] || date.beginning_of_day }
  end

  def load_habits_for_today
    Habit.active.ordered.includes(:habit_completions).select { |h| h.scheduled_for?(Date.current) }
  end
end
