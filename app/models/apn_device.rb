class ApnDevice < APN::Device
  attr_accessible :host_name, :pass_key, :token, :app_id
  
  #### Associations ####
  has_many :machines, :dependent => :destroy
  
  #### Validations ####
  validates :host_name, presence: true
#  validates :token , :uniqueness => true


  #### Methods ####
  def pass_key_in_hash
    { pass_key: pass_key }
  end
    
end
