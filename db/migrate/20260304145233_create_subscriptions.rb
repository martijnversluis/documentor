class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.string :name, null: false
      t.text :description
      t.date :starts_on
      t.date :ends_on
      t.boolean :auto_renew, default: false, null: false
      t.integer :cost_cents
      t.string :cost_frequency
      t.string :portal_url
      t.string :portal_username
      t.references :dossier, null: true, foreign_key: true
      t.datetime :archived_at

      t.timestamps
    end
  end
end
