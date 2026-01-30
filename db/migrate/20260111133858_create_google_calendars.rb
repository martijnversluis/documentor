class CreateGoogleCalendars < ActiveRecord::Migration[8.0]
  def change
    create_table :google_calendars do |t|
      t.references :google_account, null: false, foreign_key: true
      t.string :calendar_id, null: false
      t.string :name
      t.string :color
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :google_calendars, [:google_account_id, :calendar_id], unique: true
  end
end
