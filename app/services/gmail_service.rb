require "google/apis/gmail_v1"
require "nokogiri"

class GmailService
  class AuthorizationError < StandardError; end
  class TokenRefreshError < StandardError; end

  def initialize(google_account)
    @account = google_account
  end

  # Fetch unread inbox conversations, one entry per thread.
  def unread_messages(max_results: 20)
    refresh_token_if_needed!
    service = gmail_service

    result = service.list_user_threads(
      "me",
      q: "is:unread in:inbox",
      max_results: max_results
    )

    return [] unless result.threads.present?

    result.threads.map do |thread_stub|
      fetch_thread_details(service, thread_stub.id)
    end.compact
  rescue Google::Apis::AuthorizationError => e
    raise AuthorizationError, "Gmail token is invalid or expired: #{e.message}"
  end

  def mark_thread_as_read(thread_id)
    refresh_token_if_needed!
    service = gmail_service

    modify_request = Google::Apis::GmailV1::ModifyThreadRequest.new(
      remove_label_ids: ["UNREAD"]
    )
    service.modify_thread("me", thread_id, modify_request)
  rescue Google::Apis::ClientError => e
    Rails.logger.warn "Failed to mark thread #{thread_id} as read: #{e.message}"
    raise
  end

  def trash_thread(thread_id)
    refresh_token_if_needed!
    service = gmail_service
    service.trash_user_thread("me", thread_id)
  rescue Google::Apis::ClientError => e
    Rails.logger.warn "Failed to trash thread #{thread_id}: #{e.message}"
    raise
  end

  private

  def fetch_thread_details(service, thread_id)
    thread = service.get_user_thread("me", thread_id, format: "full")
    messages = thread.messages || []
    return nil if messages.empty?

    # Prefer the newest unread message so subject/from reflect the item that made the thread unread.
    message = messages.reverse.find { |m| m.label_ids&.include?("UNREAD") } || messages.last

    headers = message.payload.headers.to_h { |h| [h.name.downcase, h.value] }

    html_body = extract_html_body(message.payload)
    cta = extract_cta(html_body) if html_body.present?

    {
      id: message.id,
      thread_id: thread_id,
      message_count: messages.size,
      snippet: message.snippet,
      subject: headers["subject"] || "(geen onderwerp)",
      from: parse_from_header(headers["from"]),
      from_raw: headers["from"],
      date: parse_date(headers["date"]),
      labels: message.label_ids || [],
      cta: cta
    }
  rescue Google::Apis::ClientError => e
    Rails.logger.warn "Failed to fetch thread #{thread_id}: #{e.message}"
    nil
  end

  def parse_from_header(from)
    return "Onbekend" if from.blank?

    # Extract name from "Name <email>" format
    if from =~ /^"?([^"<]+)"?\s*<[^>]+>$/
      $1.strip
    elsif from =~ /^<([^>]+)>$/
      $1
    else
      from.split("@").first
    end
  end

  def parse_date(date_str)
    return nil if date_str.blank?
    Time.parse(date_str)
  rescue ArgumentError
    nil
  end

  def gmail_service
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = authorization_client
    service
  end

  def authorization_client
    Signet::OAuth2::Client.new(
      client_id: GoogleCalendarService.credentials[:client_id],
      client_secret: GoogleCalendarService.credentials[:client_secret],
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

  def extract_html_body(payload)
    # Direct HTML part
    if payload.mime_type == "text/html" && payload.body&.data.present?
      return decode_body_data(payload.body.data)
    end

    # Check parts for multipart messages
    return nil unless payload.parts.present?

    payload.parts.each do |part|
      if part.mime_type == "text/html" && part.body&.data.present?
        return decode_body_data(part.body.data)
      end

      # Check nested parts (for multipart/alternative inside multipart/mixed)
      if part.parts.present?
        part.parts.each do |nested_part|
          if nested_part.mime_type == "text/html" && nested_part.body&.data.present?
            return decode_body_data(nested_part.body.data)
          end
        end
      end
    end

    nil
  rescue StandardError => e
    Rails.logger.warn "Failed to extract HTML body: #{e.message}"
    nil
  end

  def decode_body_data(data)
    # Gmail sometimes returns already-decoded HTML (especially for smaller messages)
    return data if data.start_with?("<")

    # Try URL-safe base64 first (Gmail's default), then regular base64
    Base64.urlsafe_decode64(data)
  rescue ArgumentError
    Base64.decode64(data)
  end

  def extract_cta(html)
    return nil if html.blank?

    doc = Nokogiri::HTML(html)

    # Common CTA patterns to look for (in order of priority)
    cta_selectors = [
      # Explicit button classes
      'a[class*="button"]',
      'a[class*="btn"]',
      'a[class*="cta"]',
      # Links inside table cells that look like buttons (common email pattern)
      'td[class*="button"] a',
      'td[class*="btn"] a',
      # Links with button-like inline styles
      'a[style*="background"]',
      # Common service-specific patterns
      'a[href*="sentry.io"]',
      'a[href*="calendar.google.com"]',
      'a[href*="github.com"]',
      'a[href*="stripe.com/dashboard"]',
      'a[href*="linear.app"]',
      'a[href*="notion.so"]',
      'a[href*="slack.com"]'
    ]

    # URLs to skip (unsubscribe, tracking, etc.)
    skip_patterns = [
      /unsubscribe/i,
      /mailto:/i,
      /preferences/i,
      /opt.out/i,
      /email.settings/i,
      /manage.*notifications/i,
      /privacy/i,
      /terms/i
    ]

    cta_selectors.each do |selector|
      doc.css(selector).each do |link|
        href = link["href"]
        next if href.blank?
        next if skip_patterns.any? { |pattern| href.match?(pattern) }

        text = link.text.strip.gsub(/\s+/, " ")
        next if text.blank? || text.length > 50

        # Skip generic/boring link texts
        next if text.match?(/^(click here|learn more|read more|view online|view in browser)$/i)

        return { url: href, text: text }
      end
    end

    nil
  rescue StandardError => e
    Rails.logger.warn "Failed to extract CTA: #{e.message}"
    nil
  end
end
