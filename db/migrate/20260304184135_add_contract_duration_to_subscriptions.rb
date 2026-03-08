class AddContractDurationToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :contract_duration, :string
  end
end
