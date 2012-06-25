class Machine < ActiveRecord::Base
  attr_accessible :machine_name, :mac_address, :apn_device_id
  
  belongs_to :apn_device
  
  validates :machine_name, :mac_address, presence: true
  validates :mac_address, :uniqueness => true
end
