class CreateHabits < ActiveRecord::Migration[8.0]
  def change
    create_table :habits do |t|
      t.string :name, null: false
      t.text :description
      t.string :frequency, null: false, default: "daily"
      t.string :target_days # JSON array of day numbers (0=Sun, 1=Mon, etc.) for weekly habits
      t.string :color, default: "blue"
      t.boolean :active, null: false, default: true
      t.integer :position

      t.timestamps
    end

    add_index :habits, :active
    add_index :habits, :position
  end
end
