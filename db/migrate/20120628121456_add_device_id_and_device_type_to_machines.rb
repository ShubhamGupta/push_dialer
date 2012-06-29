class AddDeviceIdAndDeviceTypeToMachines < ActiveRecord::Migration
  def self.up
  	add_column :machines,  :device_id, :integer
  	add_column :machines, :device_type, :string
  end
  
  def self.down
  	remove_column :machines, :device_id
  	remove_column :machines, :device_type
  end
end
