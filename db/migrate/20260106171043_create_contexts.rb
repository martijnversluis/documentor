class CreateContexts < ActiveRecord::Migration[8.0]
  def change
    create_table :contexts do |t|
      t.string :name, null: false
      t.integer :position

      t.timestamps
    end

    add_index :contexts, :name, unique: true
    add_index :contexts, :position

    # Seed default contexts
    reversible do |dir|
      dir.up do
        %w[telefoon computer kantoor thuis boodschappen ergens].each_with_index do |name, index|
          execute "INSERT INTO contexts (name, position, created_at, updated_at) VALUES ('#{name}', #{index}, NOW(), NOW())"
        end
      end
    end
  end
end
