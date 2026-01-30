class RemoveFieldsFromParties < ActiveRecord::Migration[8.0]
  def change
    remove_column :parties, :kvk_number, :string
    remove_column :parties, :address, :string
    remove_column :parties, :postal_code, :string
    remove_column :parties, :city, :string
    remove_column :parties, :phone, :string
    remove_column :parties, :email, :string
    remove_column :parties, :website, :string
  end
end
