class AndroidDevice < ActiveRecord::Base
  # attr_accessible :title, :body

  include HTTParty

  attr_accessible :host_name, :pass_key, :token, :registration_id
  
  #### Associations ####
  has_many :machines, :as => :device, :dependent => :destroy

  #### Validations ####
  validates :token, :registration_id, presence: true, :uniqueness => true

	def notify_device(message)
		# send message to android
		self.send_push_notification(message)
	end
	
	def call_device tel, text = nil
		self.send_push_notification(:tel => tel, :sms => text)
		#send request to google URL
	end
  
  def send_push_notification(message=nil, tel=nil, sms=nil)
    parameters = Hash.new
    parameters["data.message"] = message unless message.blank?
    if !tel.blank? && !sms.blank?
      parameters["data.number"] = "sms:#{tel}"
      parameters["data.sms"] = sms
    elsif !tel.blank? && sms.blank?
      parameters["data.number"] = "tel:#{tel}" unless tel.blank?
    end
    
    options = { :body =>    { 'registration_id' => registration_id,
                              'collapse_key'    => '0'
                            }.merge(parameters), 
                :headers => { "Authorization" => ANDROID_HEADER_AUTH } 
              }
    HTTParty.post(AC2DM_URL, options)
  end

  #### Methods ####
  def pass_key_in_hash
    { pass_key: pass_key }
  end
  
  def in_hash
    {
      :token => token,
      :host_name => host_name,
      :pass_key => pass_key
    }
  end
    
end
