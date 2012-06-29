class RenameDeviceTypeInMachine < ActiveRecord::Migration
  def up
    rename_column :machines, :device_id, :phone_id
    rename_column :machines, :device_type, :phone_type
  end

  def down
    rename_column :machines, :phone_id, :device_id
    rename_column :machines, :phone_type, :device_type
  end
end
