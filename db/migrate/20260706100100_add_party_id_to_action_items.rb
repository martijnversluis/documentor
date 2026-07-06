class AddPartyIdToActionItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :action_items, :party, foreign_key: true, index: true
  end
end
