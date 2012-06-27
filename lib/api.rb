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
#      before { authenticate! } # added to each resource for limiting un-authorized access

    	#Below method returns the randomly* generated pass_key in valid json format
    	#Scenario : device sends post request for pairing
    	#params[:token]
    	#Optional params => host_name
    	post 'create' do
		    	error!({ 'error' => "Please send token" }, 412)	if !params[:token]
		    	device = ApnDevice.find_by_token(params[:token])
		    	device = ApnDevice.new(:host_name=> params[:host_name] || "Device", :token=>params[:token] ) if !device
		    	device.pass_key = 10000+rand(89999)
		    	if device.valid?
		    		device.pass_key_in_hash if device.save!(:validate => true)
		    	else
		    		if params[:token].size > 100 and device.save!(:validate => false)
				  		device.errors.clear
				  		device.pass_key_in_hash 
		    		else
		    			error!({ 'error' => "Invalid token" }, 412)
		    		end
		    	end
      end
      
      #Request from mac : sends request to get the iPhone with which it is paired
      #Needed when app launched in MAC
      get '/show' do
      	error!({ 'error' => "Mac Address Not Found" }, 412) if !params[:mac_address]
      	machine = Machine.find_by_mac_address params[:mac_address]
        machine.apn_device.in_hash if machine
      end
      
    end #resource ApnDevice
    
    resource 'machines' do
#    	before { authenticate! }
		  #This method returns all machines paired with the device. ie: list of macs -- -- so they can be unpaired
		  #Request by device params[:token]
    	get '/index'	do
    		error!({ 'error' => "Device Token Not Found" }, 412) if !params[:token]
    		device = ApnDevice.find_by_token(params[:token])
    		if device
#    		Hash["machines", device.machines.to_json]
    		"{\"machines\": #{device.machines.to_json}}"
#		  		device.machines.each do|machine| 
#		  			mach << {mac: machine.mac_address, name: machine.machine_name }
#		  		end
#						mach.to_json
    		end
    	end
    	
      # Mac sends request to pair with an device. 
      # params -> Mac address and machine_name and 5-digit pass_key

			post '/create' do
			  error!({ 'error' => "Invalid Request" }, 412) if ! (params[:mac_address] and params[:pass_key])
				device = ApnDevice.find_by_pass_key(params[:pass_key])
				if device
					machine = Machine.new(:mac_address => params[:mac_address], :machine_name => params[:machine_name] || "Mac")
					machine.apn_device_id = device.id 
					if machine.save
						if device.update_attributes(:pass_key => nil)
							device.notify_device("#{machine.machine_name} paired successfully.")  #And
							{ 'Response' => 'Pairing successful' }                                #Send success message to Mac
						end
					else
            # Send error message to Mac "Pairing failed. Try again"
            error!({ 'error' => 'Pairing failed. Try again' }, 500)               # 500: Internal Server Error
					end
				else
          # send error message to MAC for invalid pass_key
          error!({ 'error' => 'invalid pass_key', 'params' => params[:pass_key] }, 401) # 401: Unauthorized
				end
			end
			

			#unpairing from MAC Or device
			post '/unpair' do

			  error!({ 'error' => "Mac Address Not Found" }, 412) if !params[:mac_address]
		  	if params[:token]   # unpairing from device
		  		device = ApnDevice.find_by_token params[:token] 
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
						machine.apn_device.notify_device( "#{machine.machine_name} unpaired." )
		  		else
		  			{ 'Response' => 'Machine already unpaired' }
		  		end
		  	end
		  end
		  
      # connect is for sending call or text request to the device.
      # params -> MAC address, tel, sms (optional) 
		  post '/connect' do
		  	error!({ 'error' => "Mac Address Not Found" }, 412) if !params[:mac_address]
		  	machine = Machine.find_by_mac_address(params[:mac_address])
		  	if machine && params[:tel]
					if params[:tel].to_i > 0 and params[:tel].size == 10 
						machine.apn_device.call_device(params[:tel], params[:sms])
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
