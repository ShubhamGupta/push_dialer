require 'apn_on_rails'

module PushDialer

	class API < Grape::API

  	format :json
  	default_format :json
  	error_format :json
    prefix 'api'
    
    version 'v1', :using => :path
    
   rescue_from :all do |e|
     rack_response({ :message => "rescued from #{e.class.name}" })
   end

    helpers do
      # see https://github.com/intridea/grape/wiki/Accessing-parameters-and-headers
      def authenticate!
        error!('401 Unauthorized', 401) unless env['HTTP_AUTHORIZATION'] == "HUMPTyVIN-SOlPUsH-DIaLERdUMPTY"
      end
    end
    
    # GET /version
    #   Retrieves the current api version
    #
    # Headers
    #   none
    #
    # Params
    #   none
    #
    # Example
    #   
    #   curl -X GET http://localhost:3000/api/v1/version
    #
    # Returns a hash with the api's version information
    get :version do
      {version: 1, vendor: 'remote dialer'}
    end
    
    resource 'apn_devices' do
      before { authenticate! } # added to each resource for limiting un-authorized access

    	#Below method returns the randomly* generated pass_key in valid json format
    	#Scenario : device sends post request for pairing
    	#params[:token] alias for android_id
    	#params[:registration_id] => In case of android
    	#Optional params => host_name
    	post 'create' do
		    	error!({ 'error' => "Please send token" }, 412)	unless params[:token]
		    	device = ApnDevice.find_by_token(params[:token]) || AndroidDevice.find_by_token(params[:token])
		    	if params[:registration_id]  #It is an android 
		    		device = AndroidDevice.new(:host_name=> params[:host_name] || "AndroidDevice", :token=>params[:token], :registration_id => params[:registration_id] ) if !device
		    	else
		    		device = ApnDevice.new(:host_name=> params[:host_name] || "AppleDevice", :token=>params[:token] ) if !device
		    	end
		    	
		    	device.pass_key = 10000+rand(89999)
#		    	if device.valid?
	    		error!({ 'error' => "Can't save the device. #{device.errors.messages}" }, 412) unless device.save
	    		device.pass_key_in_hash
      end
      
      #Request from mac : sends request to get the device with which it is paired
      #Needed when app launched in MAC
      get '/show' do
      	error!({ 'error' => "Mac Address Not Found" }, 412) unless params[:mac_address]
      	machine = Machine.find_by_mac_address params[:mac_address]
        #Returning token, host_name and pass_key
        error!({ 'error' => "You are not paired to any device." }, 412) unless machine
        machine.device.in_hash# if machine
      end
      
    end #resource ApnDevice
    
    resource 'machines' do
      before { authenticate! }
		  #This method returns all machines paired with the device. ie: list of macs -- -- so they can be unpaired
		  #Request by device params[:token]
    	get '/index'	do
    		error!({ 'error' => "Device Token Not Found" }, 412) unless params[:token]
    		device = ApnDevice.where(:token => params[:token]).first || AndroidDevice.where(:token => params[:token]).first
    		
    		
    		#{ 'Response' => 'No Device' } unless device
    		if device
    			"{\"machines\": #{device.machines.to_json}}"
    		else
    			error!({ 'error' => "Device Not Found" }, 412)
    		end
    	end
    	
      # Mac sends request to pair with an device. 
      # params -> Mac address and machine_name and 5-digit pass_key

			post '/create' do
			  error!({ 'error' => "Invalid Request" }, 412) unless (params[:mac_address] and params[:pass_key])
				device = ApnDevice.find_by_pass_key(params[:pass_key]) || AndroidDevice.find_by_pass_key(params[:pass_key])
				if device
					machine = Machine.new(:mac_address => params[:mac_address], :machine_name => params[:machine_name] || "Mac")
#					machine.apn_device_id = device.id 
#					machine.device = device
					machine.device_id= device.id
					machine.device_type = device.class.name
					if machine.save
						if device.update_attributes(:pass_key => nil)
							#Send success message to Mac and push notification
							device.notify_device("#{machine.machine_name} paired successfully.")
							{ 'Response' => 'Pairing successful' }                                
						end
					else
            # Send error message to Mac "Pairing failed. Try again"
            error!({ 'error' => 'Pairing failed. Try again' }, 500)               
            # 500: Internal Server Error
					end
				else
          # send error message to MAC for invalid pass_key, ie Device not found
          error!({ 'error' => 'invalid pass_key', 'params' => params[:pass_key] }, 401) # 401: Unauthorized
				end
			end
			

			#unpairing from MAC Or device
			post '/unpair' do

			  error!({ 'error' => "Mac Address Not Found" }, 412) unless params[:mac_address]
		  	if params[:token]   # unpairing from device
		  		device = ApnDevice.where(:token => params[:token]).first || AndroidDevice.where(:token => params[:token]).first
		  		if device && device.machines.find_by_mac_address(params[:mac_address])  # machine belongs to that device from which request came 
						machine = Machine.find_by_mac_address(params[:mac_address])# unpaired from device
						machine.destroy if machine
						device.machines
						# Device successfully unpaired
		  		else
            # error message to device # unpairing failed
            error!({ 'error' => 'unpairing failed' }, 412)# 412: Precondition Failed
		  		end
		  	else
		  		machine = Machine.find_by_mac_address(params[:mac_address])# unpaired from mac
		  		if machine
						machine.destroy
						#Push notification to device
						machine.device.notify_device( "#{machine.machine_name} unpaired." )
		  		else
		  			{ 'Response' => 'Machine already unpaired' }
		  		end
		  	end
		  end
		  
      # connect is for sending call or text request to the device.
      # params -> MAC address, tel, sms (optional) 
		  post '/connect' do
		  	error!({ 'error' => "Mac Address Not Found" }, 412) unless params[:mac_address]
		  	machine = Machine.find_by_mac_address(params[:mac_address])
		  	if machine && params[:tel]
					if params[:tel].to_i > 0 and params[:tel].size == 10 
						machine.device.call_device(params[:tel], params[:sms])
						{ 'Response' => 'Call Initiation Request Sent' }
					else
						error!({ 'error' => 'Invalid No.', 'Tel' => params[:tel] }, 401)
					end
		  	else
		  		#Error message to machine
          error!({ 'error' => 'Cant connect', 'params' => params[:mac_address] }, 401)
		  	end 
		  end
		  
		end #resource machine
    
  end #Class
end #Module
