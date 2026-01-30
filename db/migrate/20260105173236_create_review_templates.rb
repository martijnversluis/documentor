class CreateReviewTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :review_templates do |t|
      t.string :review_type, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :review_templates, [:review_type, :active]
  end
end
