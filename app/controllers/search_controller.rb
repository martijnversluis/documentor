class SearchController < ApplicationController
  def index
    @query = params[:q]

    if @query.present?
      @dossiers = search_with_fallback(Dossier.active, :name, :description, order: "created_at DESC")
      @documents = search_with_fallback(Document.unscoped, :name, :content_text, :remarks, order: "COALESCE(occurred_at, created_at) DESC")
      @notes = search_with_fallback(Note.unscoped, :title, :content, order: "COALESCE(occurred_at, created_at) DESC")
      @action_items = search_with_fallback(ActionItem, :description, order: "created_at DESC")
      @meetings = search_with_fallback(Meeting, :title, :notes, order: "start_time DESC")
    else
      @dossiers = []
      @documents = []
      @notes = []
      @action_items = []
      @meetings = []
    end
  end

  def quick
    query = params[:q].to_s.strip
    results = []

    if query.length >= 2
      # Search dossiers
      search_with_fallback(Dossier.active, :name, :description, limit: 2).each do |dossier|
        results << {
          type: "dossier",
          name: dossier.name,
          url: dossier_path(dossier),
          icon: "folder"
        }
      end

      # Search documents
      search_with_fallback(Document.unscoped, :name, :content_text, :remarks, limit: 2).each do |doc|
        results << {
          type: "document",
          name: doc.name,
          description: doc.dossier&.name || doc.folder&.dossier&.name,
          url: document_path(doc),
          icon: "document"
        }
      end

      # Search notes
      search_with_fallback(Note.unscoped, :title, :content, limit: 2).each do |note|
        results << {
          type: "note",
          name: note.title,
          description: note.dossier&.name || note.folder&.dossier&.name,
          url: note_path(note),
          icon: "note"
        }
      end

      # Search action items
      search_with_fallback(ActionItem, :description, limit: 2).each do |item|
        results << {
          type: "action_item",
          name: item.description.truncate(50),
          description: item.dossier&.name || "Inbox",
          url: action_item_path(item),
          icon: "action_item"
        }
      end

      # Search meetings
      search_with_fallback(Meeting, :title, :notes, limit: 2).each do |meeting|
        results << {
          type: "meeting",
          name: meeting.title.truncate(50),
          description: meeting.start_time.strftime("%d-%m-%Y %H:%M"),
          url: meeting_path(meeting),
          icon: "meeting"
        }
      end

      # Sort by relevance and take top 8
      results = results.first(8)
    end

    render json: results
  end

  private

  def search_with_fallback(scope, *columns, order: nil, limit: 20)
    query = @query || params[:q].to_s.strip
    results = scope.search(query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC#{", #{order}" if order}")).limit(limit).to_a

    if results.size < limit
      ilike_conditions = columns.map { |col| "#{col} ILIKE :pattern" }.join(" OR ")
      fallback = scope.where(ilike_conditions, pattern: "%#{query}%")
      fallback = fallback.where.not(id: results.map(&:id)) if results.any?
      fallback = fallback.reorder(Arel.sql(order)) if order
      results += fallback.limit(limit - results.size).to_a
    end

    results
  end
end
