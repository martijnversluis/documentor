class AddMailEnabledToGoogleAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :google_accounts, :mail_enabled, :boolean, default: false, null: false
  end
end
