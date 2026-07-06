class AddContactFieldsToParties < ActiveRecord::Migration[8.0]
  def change
    change_table :parties do |t|
      t.string :phone
      t.string :email
      t.string :address
      t.string :postal_code
      t.string :city
      t.string :website
    end
  end
end
