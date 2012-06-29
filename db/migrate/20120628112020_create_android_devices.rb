class CreateAndroidDevices < ActiveRecord::Migration
  def change
    create_table :android_devices do |t|
    	t.text :token, :null => false
			t.string :host_name
			t.string :pass_key
			t.text :registration_id
      t.timestamps
    end
  end
end
