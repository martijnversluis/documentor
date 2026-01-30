class CreateReviewSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :review_steps do |t|
      t.references :review, null: false, foreign_key: true
      t.references :review_template_step, foreign_key: { on_delete: :nullify }
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false
      t.string :status, default: "pending", null: false
      t.text :notes
      t.datetime :completed_at

      t.timestamps
    end

    add_index :review_steps, [:review_id, :position]
    add_index :review_steps, [:review_id, :status]
  end
end
