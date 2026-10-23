class CreateImapAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :imap_accounts do |t|
      t.string :label, null: false
      t.string :host, null: false
      t.integer :port, null: false, default: 993
      t.string :username, null: false
      t.text :password, null: false
      t.string :folder, null: false, default: "INBOX"
      t.boolean :enabled, null: false, default: true
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :imap_accounts, [:username, :host], unique: true, where: "discarded_at IS NULL"
  end
end
