class AddEncryptedValueToAppSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :app_settings, :encrypted_value, :text
  end
end
