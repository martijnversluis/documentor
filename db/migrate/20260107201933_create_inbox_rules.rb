class CreateInboxRules < ActiveRecord::Migration[8.0]
  def change
    create_table :inbox_rules do |t|
      t.string :term
      t.references :dossier, null: false, foreign_key: true

      t.timestamps
    end
  end
end
