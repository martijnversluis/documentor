class CreateWastePickups < ActiveRecord::Migration[8.0]
  def change
    create_table :waste_pickups do |t|
      t.date :collection_date, null: false
      t.string :waste_type, null: false

      t.timestamps
    end

    add_index :waste_pickups, :collection_date
    add_index :waste_pickups, [:collection_date, :waste_type], unique: true
  end
end
