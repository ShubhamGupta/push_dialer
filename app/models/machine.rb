class Machine < ActiveRecord::Base
  attr_accessible :machine_name, :mac_address, :apn_device_id
  
  belongs_to :apn_device
  
  validates :machine_name, :mac_address, :apn_device_id, presence: true
  validates :mac_address, :uniqueness => true
  validates_format_of :mac_address, :with => /^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$/
  
  
  # override super#to_json to hide certain attributes
  def to_json(options={})
    {
      # :id => id,
      :mac_address => mac_address,
      :machine_name => machine_name
    }
  end
  
end
