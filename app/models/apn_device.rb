class APN::Device
  self.abstract_class = true
end

require 'rake'
class ApnDevice < APN::Device
  set_table_name 'apn_devices'
  
  include HTTParty

  attr_accessible :host_name, :pass_key, :token, :app_id
  
  #### Associations ####
  has_many :machines, :as => :phone, :dependent => :destroy
  
  #### Validations ####


#	def is_iphone?
#		self.token.length < 80
#	end

	def notify_device(message)
		notification = APN::Notification.new
		notification.device = self
		notification.sound = "default"
		notification.alert = {show: message}
		notification.save
		ApnDevice.send_push_notification
	end
	
	def call_device tel, text = nil
		notification = APN::Notification.new
		notification.device = self
		notification.sound = "default"
#			notification.alert = {tel: tel, sms: text}
		if text.blank?
			notification.alert = {call: tel}
			notification.custom_properties = {:number => tel}
#			notification.body = {call: tel}
		else
			notification.alert = {sms: tel }
			notification.custom_properties = {:number => tel, :message =>  text}
#			notification.body = {message: text}
		end 
		notification.save
		#send push notification
		ApnDevice.send_push_notification
	end

  def self.send_push_notification
		rake = Rake::Application.new
		Rake.application = rake
		rake.init
		rake.load_rakefile
  	Rake::Task["apn:notifications:deliver"].invoke
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
