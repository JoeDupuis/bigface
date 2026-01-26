class AddIndexToActionPushNativeDevicesToken < ActiveRecord::Migration[8.1]
  def change
    add_index :action_push_native_devices, :token, unique: true
  end
end
