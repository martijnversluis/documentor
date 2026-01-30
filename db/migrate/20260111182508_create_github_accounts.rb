class CreateGithubAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :github_accounts do |t|
      t.string :username, null: false
      t.text :access_token, null: false
      t.boolean :notification_sync_enabled, default: true
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :github_accounts, :username, unique: true
  end
end
