class SearchController < ApplicationController
  def index
    @query = params[:q]

    if @query.present?
      @dossiers = Dossier.active.search(@query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC, created_at DESC")).limit(20).to_a
      @documents = Document.unscoped.search(@query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC, COALESCE(occurred_at, created_at) DESC")).limit(20).to_a
      @notes = Note.unscoped.search(@query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC, COALESCE(occurred_at, created_at) DESC")).limit(20).to_a
      @action_items = ActionItem.search(@query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC, created_at DESC")).limit(20).to_a
      @meetings = Meeting.search(@query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC, start_time DESC")).limit(20).to_a
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
      Dossier.active.search(query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC")).limit(2).each do |dossier|
        results << {
          type: "dossier",
          name: dossier.name,
          url: dossier_path(dossier),
          icon: "folder"
        }
      end

      # Search documents
      Document.unscoped.search(query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC")).limit(2).each do |doc|
        results << {
          type: "document",
          name: doc.name,
          description: doc.dossier&.name || doc.folder&.dossier&.name,
          url: document_path(doc),
          icon: "document"
        }
      end

      # Search notes
      Note.unscoped.search(query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC")).limit(2).each do |note|
        results << {
          type: "note",
          name: note.title,
          description: note.dossier&.name || note.folder&.dossier&.name,
          url: note_path(note),
          icon: "note"
        }
      end

      # Search action items
      ActionItem.search(query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC")).limit(2).each do |item|
        results << {
          type: "action_item",
          name: item.description.truncate(50),
          description: item.dossier&.name || "Inbox",
          url: action_item_path(item),
          icon: "action_item"
        }
      end

      # Search meetings
      Meeting.search(query).with_pg_search_rank.reorder(Arel.sql("pg_search_rank DESC")).limit(2).each do |meeting|
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
end
