class RemoveApnDeviceIdFromMachines < ActiveRecord::Migration
  def up
  	remove_column :machines, :apn_device_id
  end

  def down
  	add_column :machines, :apn_device_id, :integer
  end
end
