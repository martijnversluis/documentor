class CreateGithubHiddenItems < ActiveRecord::Migration[8.0]
  def change
    create_table :github_hidden_items do |t|
      t.string :item_id, null: false
      t.string :action, null: false

      t.timestamps
    end

    add_index :github_hidden_items, :item_id, unique: true
  end
end
