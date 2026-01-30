class MeetingsController < ApplicationController
  before_action :set_meeting, only: [:show, :update]

  def index
    @meetings = Meeting.with_content.recent.includes(:action_items).limit(50)
  end

  def show
  end

  def update
    if @meeting.update(meeting_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @meeting }
        format.text { render plain: helpers.markdown(@meeting.notes) }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def enter
    google_account = GoogleAccount.find(params[:google_account_id])
    event_id = params[:event_id]
    event_data = params.permit(:title, :start_time, :end_time, :html_link)

    meeting = Meeting.find_or_initialize_by(
      google_account: google_account,
      google_event_id: event_id
    )

    if meeting.new_record?
      meeting.assign_attributes(
        title: event_data[:title],
        start_time: event_data[:start_time],
        end_time: event_data[:end_time],
        html_link: event_data[:html_link]
      )
      meeting.save!
    end

    redirect_to meeting
  end

  def banner
    # Bypass cache to always get fresh data
    @ongoing_meetings = GoogleCalendarService.ongoing_meetings
  rescue StandardError => e
    Rails.logger.warn "Failed to fetch ongoing meetings: #{e.message}"
    @ongoing_meetings = []
  end

  def next_meeting
    meetings = GoogleCalendarService.ongoing_meetings
    next_meeting = meetings.first

    render json: {
      conference_url: next_meeting&.dig(:conference_url),
      title: next_meeting&.dig(:title),
      start_time: next_meeting&.dig(:start_time)
    }
  rescue StandardError => e
    Rails.logger.warn "Failed to fetch next meeting: #{e.message}"
    render json: { conference_url: nil }
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:id])
  end

  def meeting_params
    params.require(:meeting).permit(:notes)
  end
end
