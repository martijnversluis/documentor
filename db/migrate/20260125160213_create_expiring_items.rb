class CreateExpiringItems < ActiveRecord::Migration[8.0]
  def change
    create_table :expiring_items do |t|
      t.string :name
      t.date :expires_at
      t.text :description
      t.integer :notify_days_before

      t.timestamps
    end
  end
end
