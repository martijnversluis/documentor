module SearchHelper
  # Extracts a snippet of text around the search query and highlights the match
  def highlight_snippet(text, query, options = {})
    return nil if text.blank? || query.blank?

    radius = options[:radius] || 60
    normalized_text = text.gsub(/\s+/, " ").strip

    # Get excerpt around the first matching term
    query_terms = query.split(/\s+/).reject(&:blank?)
    snippet = nil

    query_terms.each do |term|
      snippet = excerpt(normalized_text, term, radius: radius)
      break if snippet.present?
    end

    return nil unless snippet.present?

    # Highlight all query terms in the snippet
    highlight(snippet, query_terms, highlighter: '<mark class="bg-yellow-200 px-0.5 rounded">\1</mark>')
  end

  # Returns the searchable content for a document (for snippet extraction)
  def document_searchable_content(document)
    [document.name, document.remarks, document.content_text].compact.join(" ")
  end

  # Returns the searchable content for a note
  def note_searchable_content(note)
    [note.title, note.content].compact.join(" ")
  end

  # Returns the searchable content for a dossier
  def dossier_searchable_content(dossier)
    [dossier.name, dossier.description].compact.join(" ")
  end

  # Returns the searchable content for an action item
  def action_item_searchable_content(item)
    [item.description, item.notes].compact.join(" ")
  end

  # Returns the searchable content for a meeting
  def meeting_searchable_content(meeting)
    [meeting.title, meeting.notes].compact.join(" ")
  end
end
