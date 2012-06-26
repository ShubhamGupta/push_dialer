class AddHostNameAndPassKeyToApnDevices < ActiveRecord::Migration
  def self.up
  	add_column :apn_devices, :host_name, :string
  	add_column :apn_devices, :pass_key, :string, :limit => 5
  end
  
  def self.down
  	remove_column :apn_devices, :host_name
  	remove_column :apn_devices, :pass_key
  end
end
