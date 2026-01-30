class InboxController < ApplicationController
  def index
    @documents = Document.unscoped.inbox.order(created_at: :desc)
    @notes = Note.unscoped.inbox.order(created_at: :desc)
    @action_items = ActionItem.inbox.pending.ordered
    @dossiers = filtered_dossiers(Dossier.active).ordered_by_name
  end
end
