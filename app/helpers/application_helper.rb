module ApplicationHelper
  class ExternalLinkRenderer < Redcarpet::Render::HTML
    def link(link, title, content)
      if external_link?(link)
        %(<a href="#{link}" target="_blank" rel="noopener noreferrer"#{title_attr(title)}>#{content}</a>)
      else
        %(<a href="#{link}"#{title_attr(title)}>#{content}</a>)
      end
    end

    def autolink(link, link_type)
      if link_type == :email
        %(<a href="mailto:#{link}">#{link}</a>)
      elsif external_link?(link)
        %(<a href="#{link}" target="_blank" rel="noopener noreferrer">#{link}</a>)
      else
        %(<a href="#{link}">#{link}</a>)
      end
    end

    private

    def external_link?(link)
      link.start_with?("http://", "https://", "//")
    end

    def title_attr(title)
      title ? %( title="#{title}") : ""
    end
  end

  def markdown(text)
    return "" if text.blank?

    renderer = ExternalLinkRenderer.new(hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      no_intra_emphasis: true
    )
    markdown.render(text).html_safe
  end

  def markdown_first_paragraph(text)
    return "" if text.blank?

    first_paragraph = text.split(/\n\s*\n/).first.to_s
    markdown(first_paragraph)
  end

  # Convert URLs in plain text to clickable links
  def auto_link(text)
    return "" if text.blank?

    url_regex = %r{(https?://[^\s<]+)}
    escaped = ERB::Util.html_escape(text)
    escaped.gsub(url_regex) do |url|
      %(<a href="#{url}" target="_blank" rel="noopener noreferrer" class="text-blue-600 hover:underline">#{url}</a>)
    end.html_safe
  end

  # Extract meeting URL from conference_url, location, or description
  # Supports: Google Meet, Zoom, Microsoft Teams, Webex, GoTo Meeting
  MEETING_URL_PATTERNS = [
    %r{https?://meet\.google\.com/[a-z-]+},
    %r{https?://[a-z0-9-]*\.?zoom\.us/[jw]/\d+[^\s<"']*},        # zoom.us/j/123 of us02web.zoom.us/j/123
    %r{https?://[a-z0-9-]*\.?zoom\.us/my/[^\s<"']+},              # zoom.us/my/username (personal rooms)
    %r{https?://[a-z0-9-]+\.zoom\.us/[^\s<"']+},                  # company.zoom.us/...
    %r{https?://teams\.microsoft\.com/l/meetup-join/[^\s<"']+},   # Teams meeting join links
    %r{https?://teams\.microsoft\.com/meet/[^\s<"']+},              # Teams /meet/ links
    %r{https?://teams\.live\.com/meet/[^\s<"']+},                   # Teams live meetings
    %r{https?://[a-z0-9-]+\.webex\.com/[^\s<"']+},
    %r{https?://gotomeet\.me/[^\s<"']+},
    %r{https?://global\.gotomeeting\.com/join/[^\s<"']+},
    %r{https?://meet\.jit\.si/[^\s<"']+},
    %r{https?://[a-z0-9-]+\.slack\.com/[^\s<"']+},
    %r{https?://app\.slack\.com/huddle/[^\s<"']+},
    %r{https?://tuple\.app/[^\s<"']+}                               # Tuple
  ].freeze

  # Waste bin icon - Nederlandse kliko kleuren (gebaseerd op foto)
  # Papier: donkergroene bak, felblauwe deksel
  # GFT: bruine bak en deksel
  # PMD/Plastic: donkergroene bak, oranje deksel
  # Restafval: donkergroene bak, donkergrijze deksel
  WASTE_BIN_COLORS = {
    "Papier" => { bin: "#3D5C3D", lid: "#0066CC" },
    "PAPER" => { bin: "#3D5C3D", lid: "#0066CC" },
    "GFT" => { bin: "#5C4033", lid: "#4A3728" },
    "GREEN" => { bin: "#5C4033", lid: "#4A3728" },
    "PMD" => { bin: "#3D5C3D", lid: "#F7941D" },
    "PACKAGES" => { bin: "#3D5C3D", lid: "#F7941D" },
    "Plastic" => { bin: "#3D5C3D", lid: "#F7941D" },
    "Restafval" => { bin: "#3D5C3D", lid: "#4A4A4A" },
    "REST" => { bin: "#3D5C3D", lid: "#4A4A4A" },
    "Rest" => { bin: "#3D5C3D", lid: "#4A4A4A" }
  }.freeze

  def waste_bin_icon(waste_type, size: 24)
    colors = WASTE_BIN_COLORS[waste_type] || { bin: "#6b7280", lid: "#374151" }

    content_tag(:svg, width: size, height: size, viewBox: "0 0 24 24", fill: "none", class: "inline-block") do
      safe_join([
        # Bin body (trapezoid shape, wider at top like real kliko)
        content_tag(:path, nil, d: "M4 8L6 21h12l2-13H4z", fill: colors[:bin]),
        # Lid (curved/domed)
        content_tag(:path, nil, d: "M3 6.5C3 5.67 3.67 5 4.5 5h15c.83 0 1.5.67 1.5 1.5V8H3V6.5z", fill: colors[:lid]),
        # Lid top curve
        content_tag(:path, nil, d: "M5 5c0-1 1.5-2 7-2s7 1 7 2", stroke: colors[:lid], "stroke-width": "2", fill: "none"),
        # Wheels
        content_tag(:circle, nil, cx: "7", cy: "22.5", r: "1.5", fill: "#1f2937"),
        content_tag(:circle, nil, cx: "17", cy: "22.5", r: "1.5", fill: "#1f2937")
      ])
    end
  end

  def car_charging_icon(size: 24)
    content_tag(:svg, width: size, height: size, viewBox: "0 0 24 24", fill: "none", class: "inline-block") do
      safe_join([
        # Car body
        content_tag(:path, nil, d: "M5 13l1.5-4.5A2 2 0 018.4 7h7.2a2 2 0 011.9 1.5L19 13", stroke: "#374151", "stroke-width": "1.5", fill: "#6b7280"),
        # Car top/roof
        content_tag(:path, nil, d: "M7 13v3a1 1 0 001 1h8a1 1 0 001-1v-3H7z", fill: "#4b5563"),
        # Windows
        content_tag(:path, nil, d: "M8 9.5l1-2h6l1 2", stroke: "#9ca3af", "stroke-width": "1", fill: "#1f2937"),
        # Wheels
        content_tag(:circle, nil, cx: "8", cy: "17", r: "2", fill: "#1f2937"),
        content_tag(:circle, nil, cx: "16", cy: "17", r: "2", fill: "#1f2937"),
        # Wheel centers
        content_tag(:circle, nil, cx: "8", cy: "17", r: "0.75", fill: "#6b7280"),
        content_tag(:circle, nil, cx: "16", cy: "17", r: "0.75", fill: "#6b7280"),
        # Battery/charging indicator (lightning bolt)
        content_tag(:path, nil, d: "M12 2l-2 4h3l-2 4", stroke: "#f59e0b", "stroke-width": "1.5", "stroke-linecap": "round", "stroke-linejoin": "round", fill: "none")
      ])
    end
  end

  def extract_meeting_url(event)
    # First priority: conference URL from Google
    return event[:conference_url] if event[:conference_url].present?

    # Search in location
    if event[:location].present?
      MEETING_URL_PATTERNS.each do |pattern|
        match = event[:location].match(pattern)
        return match[0] if match
      end
    end

    # Search in description
    if event[:description].present?
      MEETING_URL_PATTERNS.each do |pattern|
        match = event[:description].match(pattern)
        return match[0] if match
      end
    end

    nil
  end
end
