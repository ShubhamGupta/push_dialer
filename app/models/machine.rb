class Machine < ActiveRecord::Base
  attr_accessible :machine_name, :mac_address, :apn_device_id
  
  belongs_to :apn_device
  
  validates :machine_name, :mac_address, :apn_device_id, presence: true
  validates :mac_address, :uniqueness => true
  validates_format_of :mac_address, :with => /^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$/
end
