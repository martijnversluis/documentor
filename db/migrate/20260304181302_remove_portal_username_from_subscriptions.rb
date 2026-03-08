class RemovePortalUsernameFromSubscriptions < ActiveRecord::Migration[8.0]
  def change
    remove_column :subscriptions, :portal_username, :string
  end
end
