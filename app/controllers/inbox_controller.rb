class InboxController < ApplicationController
  def triage
    action_items = ActionItem.inbox.pending.ordered.to_a
    documents = Document.unscoped.inbox.includes(file_attachment: :blob).order(created_at: :desc).to_a
    notes = Note.unscoped.inbox.order(created_at: :desc).to_a

    @all_items = (action_items + documents + notes).sort_by(&:created_at).reverse

    if @all_items.empty?
      redirect_to filter_inbox_action_items_path, notice: "Inbox is leeg!"
      return
    end

    if params[:item_id].present?
      type, id = params[:item_id].split("-", 2)
      @current_item = @all_items.find { |i| item_identifier(i) == params[:item_id] }
    end
    @current_item ||= @all_items.first

    @current_index = @all_items.index(@current_item) || 0
    @total_count = @all_items.count

    if @current_item.is_a?(Document)
      @duplicate = Document.find_duplicate(@current_item)
    end
  end

  private

  def item_identifier(item)
    case item
    when ActionItem then "action_item-#{item.id}"
    when Document then "document-#{item.id}"
    when Note then "note-#{item.id}"
    end
  end
  helper_method :item_identifier
end
