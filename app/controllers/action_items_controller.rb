class ActionItemsController < ApplicationController
  before_action :set_action_item, only: [:show, :edit, :update, :destroy, :toggle, :postpone, :toggle_next_action, :assign, :update_completion_notes, :update_notes, :extract_notes]
  before_action :load_filter_counts, only: [:today, :tomorrow, :yesterday, :overdue, :waiting, :someday, :next_actions, :quick_wins, :recurring, :inbox]

  def today
    @current_filter = :today
    @filter_label = "vandaag"
    @pending_items = base_pending_scope.today
    @completed_items = recent_completed_items
    @pending_reviews = pending_reviews_for_today
    @calendar_events = load_calendar_events(Date.current)
    @meetings_by_event_id = meetings_with_content_for_events(@calendar_events)
    @habits = load_habits_for_today
    render :index
  end

  def tomorrow
    @current_filter = :tomorrow
    @filter_label = "morgen"
    @pending_items = base_pending_scope.tomorrow
    @completed_items = recent_completed_items
    @calendar_events = load_calendar_events(Date.tomorrow)
    @meetings_by_event_id = meetings_with_content_for_events(@calendar_events)
    render :index
  end

  def yesterday
    @current_filter = :yesterday
    @filter_label = "gisteren"
    @pending_items = ActionItem.none
    @completed_items = base_scope.completed_yesterday.root_items.includes(:dossier, :children).order(completed_at: :desc)
    @calendar_events = load_calendar_events(Date.yesterday)
    @meetings_by_event_id = meetings_with_content_for_events(@calendar_events)
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
    @inbox_documents = Document.unscoped.inbox.includes(file_attachment: :blob).order(created_at: :desc)
    @inbox_notes = Note.unscoped.inbox.order(created_at: :desc)

    @duplicates = {}
    @inbox_documents.each do |doc|
      duplicate = Document.find_duplicate(doc)
      @duplicates[doc.id] = duplicate if duplicate
    end

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

    all_events = load_calendar_events_for_range(@start_date, @end_date)
    @calendar_events_by_date = group_events_by_date(all_events, @days)
    @meetings_by_event_id = meetings_with_content_for_events(all_events)

    @total_events = @calendar_events_by_date.values.sum(&:size)
    @total_tasks = @action_items_by_date.values.sum(&:size)
  end

  def month
    today = Date.current

    @start_date = case month_action_name
    when "current"
      today.beginning_of_month
    when "next"
      today.next_month.beginning_of_month
    when "previous"
      today.prev_month.beginning_of_month
    else
      Date.new(params[:year].to_i, params[:number].to_i, 1)
    end

    @end_date = @start_date.end_of_month
    @month_name = l(@start_date, format: "%B %Y")

    calendar_start = @start_date.beginning_of_week(:monday)
    calendar_end = @end_date.end_of_week(:monday)
    @weeks = (calendar_start..calendar_end).each_slice(7).to_a

    @prev_month = @start_date.prev_month
    @next_month = @start_date.next_month

    @action_items_by_date = filtered_action_items(ActionItem.pending.active)
      .where(due_date: @start_date..@end_date)
      .includes(:dossier)
      .ordered
      .group_by(&:due_date)

    all_events = load_calendar_events_for_range(@start_date, @end_date)
    days = (@start_date..@end_date).to_a
    @calendar_events_by_date = group_events_by_date(all_events, days)
    @meetings_by_event_id = meetings_with_content_for_events(all_events)

    @recurring_items = filtered_action_items(ActionItem.pending.active.recurring)
      .includes(:dossier)
      .ordered

    @total_events = @calendar_events_by_date.values.sum(&:size)
    @total_tasks = @action_items_by_date.values.sum(&:size)
  end

  def show
    @recent_documents = Document.where("created_at > ?", 24.hours.ago)
                                .where.not(id: @action_item.document_ids)
                                .order(created_at: :desc)
                                .limit(10)

    if @action_item.party.present?
      @party_history = ActionItem.where(party_id: @action_item.party_id)
                                 .where.not(id: @action_item.id)
                                 .includes(:dossier)
                                 .order(Arel.sql("COALESCE(completed_at, due_date, created_at) DESC"))
                                 .limit(20)
    end
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
          format.html { redirect_back fallback_location: @action_item.dossier || filter_inbox_action_items_path }
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

  def postpone
    new_date = @action_item.next_postpone_date
    @action_item.update!(due_date: new_date)

    respond_to do |format|
      format.html { redirect_back fallback_location: today_action_items_path, notice: "Doorgeschoven naar #{I18n.l(new_date, format: :long)}" }
      format.turbo_stream
    end
  end

  def toggle_next_action
    @action_item.update!(next_action: !@action_item.next_action)

    respond_to do |format|
      format.html { redirect_back fallback_location: today_action_items_path }
      format.turbo_stream
    end
  end

  def assign
    @action_item.update(dossier_id: params[:dossier_id])

    respond_to do |format|
      format.html { redirect_to params[:redirect_to] || filter_inbox_action_items_path, notice: "Actiepunt toegewezen aan dossier" }
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

  def reschedule_overdue
    count = filtered_action_items(ActionItem.pending.active.overdue).update_all(due_date: Date.current)
    message = count == 1 ? "1 actiepunt verplaatst naar vandaag" : "#{count} actiepunten verplaatst naar vandaag"
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

  def month_action_name
    request.path.split("/month/").last.split("/").first
  end

  def set_action_item
    @action_item = ActionItem.find(params[:id])
  end

  def action_item_params
    params.require(:action_item).permit(:description, :due_date, :recurrence, :context, :dossier_id, :party_id, :waiting_for_party_id, :waiting_for_description, :someday, :estimated_minutes, :next_action, :parent_id, :notes, :status_text)
  end

  def base_scope
    @base_scope ||= filtered_action_items(ActionItem.all)
  end

  def base_pending_scope
    base_scope.pending.active.root_items.includes(:dossier, :waiting_for_party, :children).ordered
  end

  def recent_completed_items
    base_scope.completed.root_items.includes(:dossier, :children).order(completed_at: :desc).limit(20)
  end

  def load_filter_counts
    mode_key = work_mode? ? "work" : "personal:#{work_dossier_ids.sort.join(',')}"
    counts = Rails.cache.fetch("action_items/filter_counts/v1/#{Date.current}/#{mode_key}", expires_in: 5.minutes) do
      ActionItem.filter_counts(base_scope)
    end

    @today_count = counts[:today]
    @tomorrow_count = counts[:tomorrow]
    @yesterday_count = counts[:yesterday]
    @overdue_count = counts[:overdue]
    @waiting_count = counts[:waiting]
    @someday_count = counts[:someday]
    @quick_count = counts[:quick]
    @next_count = counts[:next]
    @recurring_count = counts[:recurring]
    @inbox_count = counts[:inbox]
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

    relevant_types = Review::REVIEW_TYPES.reject do |type|
      (type == "daily_start" && (weekend || current_hour >= 12)) ||
        (type == "daily_end" && (weekend || current_hour < 12))
    end
    return [] if relevant_types.empty?

    Rails.cache.fetch("pending_reviews/v2/#{Date.current}/#{current_hour}", expires_in: 5.minutes) do
      templates_by_type = ReviewTemplate.where(active: true, review_type: relevant_types).index_by(&:review_type)
      periods_by_type = relevant_types.index_with { |type| Review.period_for(type) }
      reviews_by_key = Review
        .where(review_type: relevant_types, period_key: periods_by_type.values.map { |p| p[:key] })
        .index_by { |r| [r.review_type, r.period_key] }

      relevant_types.filter_map do |type|
        template = templates_by_type[type]
        next if template.nil?

        period = periods_by_type[type]
        review = reviews_by_key[[type, period[:key]]] || Review.new(
          review_type: type,
          period_start: period[:start],
          period_end: period[:end],
          period_key: period[:key]
        )
        next if review.completed?
        next unless review.due? || review.due_soon?

        { type: type, review: review, template: template }
      end
    end
  end

  def meetings_with_content_for_events(events)
    event_ids = events.filter_map { |e| e[:event_id] }.uniq
    return {} if event_ids.empty?

    Rails.cache.fetch("meetings_with_content/v1/#{event_ids.sort.hash}", expires_in: 5.minutes) do
      Meeting.where(google_event_id: event_ids).with_content.index_by(&:google_event_id)
    end
  end

  def load_calendar_events(date)
    Rails.cache.fetch("calendar_events_#{date}", expires_in: 10.minutes) do
      fetch_calendar_events_for_range(date, date)
    end
  end

  def load_calendar_events_for_range(start_date, end_date)
    Rails.cache.fetch("calendar_events_#{start_date}_#{end_date}", expires_in: 10.minutes) do
      fetch_calendar_events_for_range(start_date, end_date)
    end
  end

  def group_events_by_date(events, days)
    grouped = {}
    days.each { |day| grouped[day] = [] }

    events.each do |event|
      event_date = (event[:start_time] || event[:end_time])&.to_date
      grouped[event_date]&.push(event) if event_date
    end

    grouped
  end

  def fetch_calendar_events_for_range(start_date, end_date)
    events = []

    GoogleAccount.includes(:google_calendars).find_each do |account|
      next unless account.enabled_calendars.any?

      begin
        service = GoogleCalendarService.new(account)
        events.concat(service.events_for_range(start_date: start_date, end_date: end_date))
      rescue GoogleCalendarService::TokenRefreshError => e
        Rails.logger.warn "Failed to load calendar events for #{account.email}: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Calendar error for #{account.email}: #{e.message}"
      end
    end

    events.sort_by { |e| e[:start_time] || start_date.beginning_of_day }
  end

  def load_habits_for_today
    Habit.active.not_archived.includes(:habit_completions)
      .select { |h| h.scheduled_for?(Date.current) }
      .sort_by { |h| [h.simple_checkbox? ? 1 : 0, h.name.downcase] }
  end
end
