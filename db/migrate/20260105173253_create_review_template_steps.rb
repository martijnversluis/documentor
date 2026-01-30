class CreateReviewTemplateSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :review_template_steps do |t|
      t.references :review_template, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :review_template_steps, [:review_template_id, :position]
  end
end
