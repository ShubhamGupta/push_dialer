require 'apn_on_rails'
module PushDialer
	class API < Grape::API
  	format :json
  	default_format :json
    prefix 'api'
    resource 'apn_devices' do
    	#Below method returns the randomly* generated pass_key in valid json format
    	#Scenario : device sends post request for pairing
    	#params[:token]
    	#Optional params => host_name
    	get 'create' do
      	device = ApnDevice.find_by_token(params[:token])
      	device = ApnDevice.new(:host_name=>params[:host_name], :token=>params[:token] ) if !device
      	device.pass_key = (rand(0.0)*100000).to_i
      	"{\"pass_key\":#{device.pass_key}}" if device.save!
      end

#Request from mac : sends request to get the device with which it is paired
#Needed when app launched in MAC
      get '/show' do
      	machine = Machine.find_by_mac_address params[:mac_address]
        ApnDevice.find(machine.apn_device_id) if machine
      end
      
    end#resource ApnDevice
    
    resource 'machines' do
    
		  #This method returns all machines paired with the device. ie: list of macs--
		  # --so they can be unpaired
		  #Request by device params[:token]
    	get '/index'	do
    		device = ApnDevice.find_by_token(params[:token])
    		device.machines if device
    	end
    	
#    	Mac sends request to pair with an device. 
#    	params -> Mac address and pass_key and machine_name

			post '/create' do
				device = ApnDevice.find_by_pass_key(params[:pass_key])
				if device
					machine = Machine.new(:mac_address => params[:mac_address], :machine_name => params[:machine_name], :apn_device_id => device.id) 
#					machine.apn_device_id = device.id
					if machine.save
						device.update_attributes(:pass_key => nil)
						device.notify_device("#{machine.machine_name} paired successfully.") #And
						#Send success message to Mac
					else
						# Send error message to Mac "Pairing failed. Try again"
					end
				else
#					send error message to MAC for invalid pass_key
				end
			end
			
			#unpairing from MAC Or device
			post '/unpair' do
		  	if params[:token] #unpairing from device
		  		device = ApnDevice.find_by_token params[:token]
					if device && device.machines.find_by_mac_address(params[:mac_address]) #machine belongs to that device from which request came 
		  			Machine.find_by_mac_address(params[:mac_address]).destroy # unpaired from device
		  			device.machines # changed ??
		  			# Device successfully unpaired
		  		else
#		  			error message to device # unpairing failed
		  		end
		  	else
		  		machine = Machine.find_by_mac_address(params[:mac_address])# unpaired from mac side
		  		machine.destroy
		  		#Push notification to device
		  		machine.apn_device.notify_device( "#{machine.machine_name} unpaired." )
		  	end
		  end
		  
# connect is for sending call or text request to the device.
# params -> MAC address, Reciever No., text (optional) 
		  get '/connect' do
		  	machine = Machine.find_by_mac_address(params[:mac_address])
		  	if machine 
#		  		machine.apn_device.call_device (params[:receiver], params[:text])
		  	else
		  		#Error message to MAC
		  	end 
		  end
		  
		end#resource machine
    
  end #Class
end #Module
