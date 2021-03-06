class AndroidDevice < ActiveRecord::Base
  # attr_accessible :title, :body

  include HTTParty

  attr_accessible :host_name, :pass_key, :token, :registration_id
  
  #### Associations ####
  has_many :machines, :as => :phone, :dependent => :destroy

  #### Validations ####
  validates :token, :registration_id, presence: true, :uniqueness => true

	def notify_device(message)
		# send message to android
		self.send_push_notification(message)
	end
	
	def custom_notify_rate(message, rating = true)
    if rating
      self.send_push_notification("RATING ::" + message)
    else
      self.send_push_notification("REMINDER ::" + message)
    end
  end
	
	def call_device tel, text = nil
		self.send_push_notification(nil, tel, text)
		#send request to google URL
	end
  
  def send_push_notification(message=nil, tel=nil, sms=nil)
    parameters = Hash.new
    parameters["data.message"] = message unless message.blank?
    if !tel.nil? && !sms.nil?
      parameters["data.number"] = "sms:#{tel}"
      parameters["data.sms"] = sms
    elsif !tel.nil? && sms.nil?
      parameters["data.number"] = "tel:#{tel}"# unless tel.blank?
    end
    
    options = { :body =>    { 'registration_id' => registration_id,
                              'collapse_key'    => '0',
                              'time_to_live'    => '30'
                            }.merge(parameters), 
                :headers => { "Authorization" => ANDROID_HEADER_AUTH,
                							"content_type" => "application/json"
                						 } 
              }
    res = HTTParty.post(AC2DM_URL, options)
    if (res =~ /registration_id/i)
    	self.update_attributes(:registration_id => res.split("registration_id=")[1])
    end
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
