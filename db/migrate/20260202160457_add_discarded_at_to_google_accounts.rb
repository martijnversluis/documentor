class AddDiscardedAtToGoogleAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :google_accounts, :discarded_at, :datetime
  end
end
