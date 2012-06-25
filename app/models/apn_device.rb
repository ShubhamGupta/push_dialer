class ApnDevice < APN::Device
  attr_accessible :host_name, :pass_key, :token, :app_id
  
  has_many :machines
  
  validates :host_name, presence: true

#  Simply override token format here
      validates_format_of :token, :with => /^((.)+ )$/ 

	def is_iphone?
		self.token.length < 80
	end

	def notify_device(message)
		notification = APN::Notification.new
		notification.device = self
		notification.sound = "default"
		notification.alert = message
		notification.save
	end

	def call_device tel,text
		if self.is_iphone?
			notification = APN::Notification.new
			notification.device = self
			notification.sound = "default"
			notification.alert = message
			notification.save
			#send push notification
		else
			#send request to google URL
		end
	end

end
