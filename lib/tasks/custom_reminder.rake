desc "Sends custom push notification to remind iPhone app user about the app and to rate the app"
task :custom_reminder => :environment do
    reminding_devices = ApnDevice.where(["updated_at <= ?", 8.days.ago(Time.now)])
    unless reminding_devices.blank?
      for device in reminding_devices
        if device.updated_at > 14.days.ago(Time.now) # Rating notification
          device.custom_notify_rate("Does Remote Dialer makes dialing easy? Please share your experience and rate us on the App Store.", true)
        else # Reminder notification for more than 2 weeks of inactivity
          device.custom_notify_rate("You haven't used Remote Dialer for a while. Use Remote Dialer and make calls and sms easily.", false)          
        end
        Rails.logger.info "Custom Notification generated for device named: #{device.host_name}"
      end
      
      #Send all pending notifications
      Rake::Task["apn:notifications:deliver"].invoke
    end
    
    reminding_android_devices = AndroidDevice.where(["updated_at <= ?", 8.days.ago(Time.now)])
    unless reminding_android_devices.blank?
      for device in reminding_android_devices
        if device.updated_at > 14.days.ago(Time.now) # Rating notification
          device.custom_notify_rate("Does Remote Dialer makes dialing easy? Please share your experience and rate us on PlayStore.", true)
        else
          device.custom_notify_rate("You haven't used Remote Dialer for a while. Use Remote Dialer and make calls and sms easily.", false)          
        end
        Rails.logger.info "Custom Notification generated for device named: #{device.host_name}"
      end
    end
end