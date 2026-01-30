class CreateParties < ActiveRecord::Migration[8.0]
  def change
    create_table :parties do |t|
      t.string :name
      t.string :kvk_number
      t.string :address
      t.string :postal_code
      t.string :city
      t.string :phone
      t.string :email
      t.string :website
      t.text :notes

      t.timestamps
    end
  end
end
