class RemoveSyncColumnsFromGithubAccounts < ActiveRecord::Migration[8.0]
  def change
    remove_column :github_accounts, :notification_sync_enabled, :boolean
    remove_column :github_accounts, :last_synced_at, :datetime
  end
end
