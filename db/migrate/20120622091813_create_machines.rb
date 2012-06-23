class CreateMachines < ActiveRecord::Migration
  def up
  	create_table :machines do |t|
      t.references :apn_device
			t.string :mac_address
			t.string :machine_name
      t.timestamps
    end
  end

  def down
  	drop_table :machines
  end
end
