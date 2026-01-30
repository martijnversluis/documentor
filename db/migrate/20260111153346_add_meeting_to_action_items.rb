class AddMeetingToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :action_items, :meeting, null: true, foreign_key: true
  end
end
