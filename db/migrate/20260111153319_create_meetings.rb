class CreateMeetings < ActiveRecord::Migration[8.0]
  def change
    create_table :meetings do |t|
      t.references :google_account, null: false, foreign_key: true
      t.string :google_event_id, null: false
      t.string :title
      t.datetime :start_time
      t.datetime :end_time
      t.text :notes
      t.string :html_link

      t.timestamps
    end

    add_index :meetings, [:google_account_id, :google_event_id], unique: true
    add_index :meetings, :start_time
  end
end
