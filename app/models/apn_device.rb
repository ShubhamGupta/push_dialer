class ApnDevice < APN::Device
  attr_accessible :host_name, :pass_key, :token, :app_id
  
  #### Associations ####
  has_many :machines, :dependent => :destroy
  
  #### Validations ####
  validates :host_name, presence: true



#  validates_format_of :token, :with => /.+/ 

	def is_iphone?
		self.token.length < 80
	end

	def notify_device(message)
		if self.is_iphone?
			notification = APN::Notification.new
			notification.device = self
			notification.sound = "default"
			notification.alert = message
			notification.save
			ApnDevice.send_push_notification_to_ios
		else
			# send message to android
		end
	end

	def call_device tel,text
		if self.is_iphone?
			notification = APN::Notification.new
			notification.device = self
			notification.sound = "default"
			notification.alert = message # where's the message ??
			notification.save
			#send push notification
			ApnDevice.send_push_notification_to_ios
		else
			#send request to google URL
		end
	end

  def self.send_push_notification_to_ios
  	Rake::Task["apn:notifications:deliver"].invoke
  end

  #### Methods ####
  def pass_key_in_hash
    { pass_key: pass_key }
  end
  
  def in_hash(options={})
    {
      :token => token,
      :host_name => host_name,
      :pass_key => pass_key
    }
  end
    
end
