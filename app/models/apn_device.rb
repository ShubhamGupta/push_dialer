require 'rake'
class ApnDevice < APN::Device

  include HTTParty

  attr_accessible :host_name, :pass_key, :token, :app_id
  
  #### Associations ####
  has_many :machines, :dependent => :destroy
#validates_format_of :token, :with => /(.)+/, :unless => Proc.new {|device| device.token.size > 10}  
  #### Validations ####
#  validates :host_name, presence: true

	def is_iphone?
		self.token.length < 80
	end

	def notify_device(message)
		if self.is_iphone?
			notification = APN::Notification.new
			notification.device = self
			notification.sound = "default"
			notification.alert = {show: message}
			notification.save
			ApnDevice.send_push_notification_to_ios
		else
			# send message to android
			ApnDevice.send_push_notification_to_android(message)
		end
	end
	
	def call_device tel, text = nil
		if self.is_iphone?
			notification = APN::Notification.new
			notification.device = self
			notification.sound = "default"
			notification.alert = {tel: tel, sms: text} # where's the message ??
			notification.save
			#send push notification
			ApnDevice.send_push_notification_to_ios
		else
			ApnDevice.send_push_notification_to_android(:tel => tel, :sms => text)
			#send request to google URL
		end
	end

  def self.send_push_notification_to_ios
  	
		rake = Rake::Application.new
		Rake.application = rake
		rake.init
		rake.load_rakefile
  	Rake::Task["apn:notifications:deliver"].invoke
  end
  
  def self.send_push_notification_to_android(message=nil, tel=nil, sms=nil)
    parameters = Hash.new
    parameters["data.message"] = message unless message.blank?
    if !tel.blank? && !sms.blank?
      parameters["data.number"] = "sms:#{tel}"
      parameters["data.sms"] = sms
    elsif !tel.blank? && sms.blank?
      parameters["data.number"] = "tel:#{tel}" unless tel.blank?
    end
    
    options = { :body =>    { 'registration_id' => token,#SAMPLE_ANDROID_REGISTRATION_ID,
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
