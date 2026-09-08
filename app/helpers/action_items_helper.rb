module ActionItemsHelper
  FILTER_PATH_HELPERS = {
    today: :today_action_items_path,
    tomorrow: :tomorrow_action_items_path,
    yesterday: :yesterday_action_items_path,
    overdue: :overdue_action_items_path,
    waiting: :waiting_action_items_path,
    someday: :someday_action_items_path,
    next_actions: :next_actions_action_items_path,
    quick_wins: :quick_wins_action_items_path,
    recurring: :recurring_action_items_path,
    inbox: :filter_inbox_action_items_path
  }.freeze

  def filter_action_items_path(filter)
    helper = FILTER_PATH_HELPERS[filter&.to_sym] || :today_action_items_path
    public_send(helper)
  end
end
