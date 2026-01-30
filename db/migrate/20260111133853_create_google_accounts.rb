class CreateGoogleAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :google_accounts do |t|
      t.string :email, null: false
      t.string :name
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at

      t.timestamps
    end

    add_index :google_accounts, :email, unique: true
  end
end
