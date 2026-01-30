class ReviewController < ApplicationController
  def index
    # Overdue items
    @overdue_items = ActionItem.pending.active.overdue.includes(:dossier).ordered

    # Dossiers without pending action items (excluding archived and someday dossiers)
    dossier_ids_with_actions = ActionItem.pending.active.where.not(dossier_id: nil).distinct.pluck(:dossier_id)
    @dossiers_without_actions = Dossier.active.where(someday: false).where.not(id: dossier_ids_with_actions).order(:name)

    # Waiting for items to follow up
    @waiting_items = ActionItem.pending.active.waiting.includes(:dossier, :waiting_for_party).ordered

    # Someday/maybe items to review
    @someday_items = ActionItem.pending.someday_maybe.includes(:dossier).order(updated_at: :asc).limit(10)

    # Inbox items that need processing
    @inbox_count = ActionItem.pending.inbox.count + Document.inbox.count + Note.inbox.count

    # Completed this week
    @completed_this_week = ActionItem.completed.where("completed_at >= ?", 1.week.ago).count
  end
end
