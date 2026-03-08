class AddReferenceToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :reference, :string
  end
end
