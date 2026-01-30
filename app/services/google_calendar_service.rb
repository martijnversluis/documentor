require "google/apis/calendar_v3"
require "googleauth"

class GoogleCalendarService
  SCOPES = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile"
  ].freeze

  class AuthorizationError < StandardError; end
  class TokenRefreshError < StandardError; end

  def initialize(google_account)
    @account = google_account
  end

  # Generate OAuth authorization URL
  def self.authorization_url(redirect_uri)
    client = Signet::OAuth2::Client.new(
      client_id: credentials[:client_id],
      client_secret: credentials[:client_secret],
      scope: SCOPES,
      redirect_uri: redirect_uri,
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      access_type: "offline",
      prompt: "consent"
    )
    client.authorization_uri.to_s
  end

  # Exchange authorization code for tokens
  def self.exchange_code(code, redirect_uri)
    client = Signet::OAuth2::Client.new(
      client_id: credentials[:client_id],
      client_secret: credentials[:client_secret],
      redirect_uri: redirect_uri,
      token_credential_uri: "https://oauth2.googleapis.com/token",
      code: code,
      grant_type: "authorization_code"
    )
    client.fetch_access_token!

    {
      access_token: client.access_token,
      refresh_token: client.refresh_token,
      expires_at: Time.current + client.expires_in.seconds
    }
  end

  # Get user info (email, name)
  def self.user_info(access_token)
    uri = URI("https://www.googleapis.com/oauth2/v2/userinfo")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    response = http.request(request)

    JSON.parse(response.body, symbolize_names: true)
  end

  # List all calendars for this account
  def calendars
    refresh_token_if_needed!
    service = calendar_service
    calendar_list = service.list_calendar_lists

    calendar_list.items.map do |cal|
      {
        id: cal.id,
        name: cal.summary,
        color: cal.background_color,
        primary: cal.primary || false
      }
    end
  end

  # Get events for a specific date from enabled calendars
  def events(date:, calendar_ids: nil)
    refresh_token_if_needed!
    service = calendar_service

    calendar_ids ||= @account.enabled_calendars.pluck(:calendar_id)
    return [] if calendar_ids.empty?

    time_min = date.in_time_zone.beginning_of_day.rfc3339
    time_max = date.in_time_zone.end_of_day.rfc3339

    all_events = []

    calendar_ids.each do |calendar_id|
      begin
        result = service.list_events(
          calendar_id,
          time_min: time_min,
          time_max: time_max,
          single_events: true,
          order_by: "startTime"
        )

        calendar = @account.google_calendars.find_by(calendar_id: calendar_id)

        result.items.each do |event|
          # Get user's response status
          response_status = extract_response_status(event, @account.email)

          all_events << {
            id: event.id,
            event_id: event.id,
            google_account_id: @account.id,
            calendar_id: calendar_id,
            calendar_name: calendar&.name,
            calendar_color: calendar&.color,
            title: event.summary,
            description: event.description,
            location: event.location,
            start_time: parse_event_time(event.start),
            end_time: parse_event_time(event.end),
            all_day: event.start&.date.present?,
            html_link: event.html_link,
            conference_url: extract_conference_url(event),
            response_status: response_status,
            reminder_minutes: extract_reminder_minutes(event)
          }
        end
      rescue Google::Apis::ClientError => e
        Rails.logger.warn "Failed to fetch events from calendar #{calendar_id}: #{e.message}"
      end
    end

    all_events.sort_by { |e| e[:start_time] || date.beginning_of_day }
  end

  # Class method to get all ongoing and upcoming meetings where user is attending
  # Returns meetings with :status of :ongoing or :upcoming (based on event's reminder time)
  # Only returns meetings that have a conference URL (video call link)
  def self.ongoing_meetings(include_upcoming: true)
    now = Time.current
    meetings = []

    GoogleAccount.find_each do |account|
      service = new(account)
      today_events = service.events(date: Date.current)

      today_events.each do |event|
        next if event[:all_day]
        next unless event[:start_time].present? && event[:end_time].present?
        next unless %w[accepted tentative].include?(event[:response_status])
        next unless event[:conference_url].present? # Only show meetings with video link

        # Check if ongoing
        if event[:start_time] <= now && event[:end_time] > now
          meetings << event.merge(meeting_status: :ongoing)
        # Check if upcoming (based on event's reminder time, default 10 minutes)
        elsif include_upcoming
          reminder_minutes = event[:reminder_minutes] || 10
          reminder_time = event[:start_time] - reminder_minutes.minutes
          if event[:start_time] > now && reminder_time <= now
            meetings << event.merge(meeting_status: :upcoming)
          end
        end
      end
    rescue TokenRefreshError
      next
    end

    meetings.sort_by { |e| e[:start_time] }
  end

  # Class method to check if any account indicates we should be working
  def self.should_be_working?
    GoogleAccount.find_each do |account|
      service = new(account)
      return true if service.currently_working?
    rescue TokenRefreshError
      next
    end
    false
  end

  # Class method to get detailed work status for display
  # Returns: { status: :working/:free/:outside_hours, label: "...", times: "09:00 - 17:00" }
  def self.work_status
    GoogleAccount.find_each do |account|
      service = new(account)
      status = service.work_status_details
      return status if status
    rescue TokenRefreshError
      next
    end
    { status: :unknown, label: nil }
  end

  # Get detailed work status for this account
  def work_status_details
    refresh_token_if_needed!

    # First check out of office
    if out_of_office_now?
      return { status: :free, label: "Vrij" }
    end

    # Check if within default working hours
    unless default_working_hours?
      return { status: :outside_hours, label: "Buiten werktijd" }
    end

    # Within working hours - optionally show location
    working_event = current_working_location_event
    if working_event
      location = working_location_label(working_event)
      return { status: :working, label: location, times: nil }
    end

    # Working hours but no location set
    { status: :working, label: nil, times: nil }
  end

  # Get current working location event details
  def current_working_location_event
    service = calendar_service
    now = Time.current
    primary_calendar_id = @account.email

    begin
      result = service.list_events(
        primary_calendar_id,
        time_min: now.rfc3339,
        time_max: (now + 1.minute).rfc3339,
        single_events: true,
        event_types: ["workingLocation"]
      )

      event = result.items.first
      return nil unless event

      {
        title: event.summary,
        start_time: parse_event_time(event.start),
        end_time: parse_event_time(event.end),
        all_day: event.start&.date.present?,
        location_type: event.working_location_properties&.type
      }
    rescue Google::Apis::ClientError => e
      Rails.logger.warn "Failed to get working location event: #{e.message}"
      nil
    end
  end

  # Check if currently within working hours and not out of office
  def currently_working?
    return false if out_of_office_now?
    return false unless default_working_hours?

    true
  end

  # Default working hours: weekdays 9-17
  def default_working_hours?
    now = Time.current
    now.wday.between?(1, 5) && now.hour.between?(9, 16)
  end

  # Check if there's an active out-of-office event right now
  def out_of_office_now?
    refresh_token_if_needed!
    service = calendar_service
    now = Time.current

    # Check primary calendar for out-of-office events
    primary_calendar = @account.google_calendars.find_by(calendar_id: @account.email) ||
                       @account.google_calendars.first

    return false unless primary_calendar

    begin
      result = service.list_events(
        primary_calendar.calendar_id,
        time_min: now.rfc3339,
        time_max: (now + 1.minute).rfc3339,
        single_events: true,
        event_types: ["outOfOffice"]
      )
      result.items.any?
    rescue Google::Apis::ClientError => e
      Rails.logger.warn "Failed to check out-of-office: #{e.message}"
      false
    end
  end

  # Check if there's an active working location event right now
  def within_working_hours?
    refresh_token_if_needed!
    service = calendar_service
    now = Time.current

    # Check primary calendar for working location events
    primary_calendar_id = @account.email

    begin
      result = service.list_events(
        primary_calendar_id,
        time_min: now.rfc3339,
        time_max: (now + 1.minute).rfc3339,
        single_events: true,
        event_types: ["workingLocation"]
      )

      # If there's a working location event active now, we're working
      result.items.any?
    rescue Google::Apis::ClientError => e
      Rails.logger.warn "Failed to check working location: #{e.message}"
      # Fallback: weekdays 9-17 are working hours
      fallback_working_hours?
    end
  end

  private

  def working_location_label(event)
    location_type = event[:location_type]
    title = event[:title]

    # Google's built-in home office type
    return "Thuis" if location_type == "homeOffice"

    # Custom location with "Thuis" or "Home" in the name - still means working from home
    if title.present?
      return "Thuis" if title.downcase.include?("thuis") || title.downcase.include?("home")
      return title
    end

    # Fallback for office or other locations
    case location_type
    when "officeLocation"
      "Kantoor"
    else
      "Werk"
    end
  end

  def format_event_times(event)
    return nil if event[:all_day]

    start_time = event[:start_time]&.strftime("%H:%M")
    end_time = event[:end_time]&.strftime("%H:%M")

    return nil unless start_time && end_time

    "#{start_time} - #{end_time}"
  end

  def fallback_working_hours?
    now = Time.current
    # Weekdays (1-5) between 9:00 and 17:00
    now.wday.between?(1, 5) && now.hour.between?(9, 16)
  end

  def calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = authorization_client
    service
  end

  def authorization_client
    Signet::OAuth2::Client.new(
      client_id: self.class.credentials[:client_id],
      client_secret: self.class.credentials[:client_secret],
      access_token: @account.access_token,
      refresh_token: @account.refresh_token,
      token_credential_uri: "https://oauth2.googleapis.com/token"
    )
  end

  def refresh_token_if_needed!
    return unless @account.token_expired?

    client = authorization_client
    begin
      client.refresh!
      @account.update!(
        access_token: client.access_token,
        token_expires_at: Time.current + client.expires_in.seconds
      )
    rescue Signet::AuthorizationError => e
      raise TokenRefreshError, "Failed to refresh token: #{e.message}"
    end
  end

  def parse_event_time(event_time)
    return nil unless event_time

    if event_time.date_time
      event_time.date_time.to_time
    elsif event_time.date
      # All-day events - date can be a String or Date
      date = event_time.date.is_a?(String) ? Date.parse(event_time.date) : event_time.date
      date.to_time
    end
  end

  def extract_conference_url(event)
    # First try Google Meet / conference data
    if event.conference_data&.entry_points.present?
      video_entry = event.conference_data.entry_points.find { |ep| ep.entry_point_type == "video" }
      return video_entry.uri if video_entry&.uri.present?
    end

    # Then check hangout link
    return event.hangout_link if event.hangout_link.present?

    # Check location for meeting URLs
    if event.location.present?
      meeting_url = extract_meeting_url_from_text(event.location)
      return meeting_url if meeting_url.present?
    end

    # Finally, look for meeting URLs in description
    if event.description.present?
      meeting_url = extract_meeting_url_from_text(event.description)
      return meeting_url if meeting_url.present?
    end

    nil
  end

  def extract_meeting_url_from_text(text)
    # Common video meeting URL patterns
    patterns = [
      %r{https?://[a-z0-9.-]*zoom\.us/j/[^\s<>"]+}i,           # Zoom
      %r{https?://meet\.google\.com/[^\s<>"]+}i,                # Google Meet
      %r{https?://teams\.microsoft\.com/[^\s<>"]+}i,            # Microsoft Teams
      %r{https?://[a-z0-9.-]*webex\.com/[^\s<>"]+}i,            # Webex
      %r{https?://[a-z0-9.-]*whereby\.com/[^\s<>"]+}i,          # Whereby
      %r{https?://[a-z0-9.-]*around\.co/[^\s<>"]+}i,            # Around
      %r{https?://[a-z0-9.-]*gather\.town/[^\s<>"]+}i,          # Gather
      %r{https?://app\.slack\.com/huddle/[^\s<>"]+}i,           # Slack Huddle
      %r{https?://tuple\.app/[^\s<>"]+}i                         # Tuple
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[0] if match
    end

    nil
  end

  def extract_reminder_minutes(event)
    return nil unless event.reminders.present?

    # If using default reminders, we don't have the specific minutes
    return nil if event.reminders.use_default

    # Get popup reminders (not email), take the last one (closest to event)
    overrides = event.reminders.overrides || []
    popup_reminders = overrides.select { |r| r.method == "popup" }

    return nil if popup_reminders.empty?

    # Return the last (smallest) reminder time
    popup_reminders.map(&:minutes).min
  end

  def extract_response_status(event, user_email)
    return "accepted" unless event.attendees.present?

    attendee = event.attendees.find { |a| a.email&.downcase == user_email&.downcase || a.self }
    attendee&.response_status || "needsAction"
  end

  def self.credentials
    Rails.application.credentials.dig(:google, :calendar) || {}
  end
end
