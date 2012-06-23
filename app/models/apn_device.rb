class ApnDevice < APN::Device
  attr_accessible :host_name, :pass_key, :token, :app_id
  
  has_many :machines
  
  validates :host_name, presence: true
#  validates :token , :uniqueness => true
end
