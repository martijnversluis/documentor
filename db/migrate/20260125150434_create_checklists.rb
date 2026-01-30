class CreateChecklists < ActiveRecord::Migration[8.0]
  def change
    create_table :checklists do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
