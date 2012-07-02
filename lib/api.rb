require 'apn_on_rails'

module PushDialer

	class API < Grape::API

  	format :json
  	default_format :json
  	error_format :json
    prefix 'api'
    
    version 'v1', :using => :path
    
#   rescue_from :all do |e|
#     rack_response({ :message => "rescued from #{e.class.name}" })
#   end

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
    	#Can move unless device to One place ????????
    	post 'create' do
		    	error!({ 'error' => "Please send token" }, 412)	unless params[:token]
		    	device = ApnDevice.where(:token => params[:token]).first || AndroidDevice.where(:token => params[:token]).first
		    	if params[:registration_id]  #It is an android 
		    		device = AndroidDevice.new(:host_name=> params[:host_name] || "AndroidDevice", :token=>params[:token], :registration_id => params[:registration_id] ) unless device
		    	else
		    		device = ApnDevice.new(:host_name=> params[:host_name] || "AppleDevice", :token=>params[:token] ) unless device
		    	end
		    	#Random 5 digit pass_key
		    	device.pass_key = 10000+rand(89999)
	    		error!({ 'error' => "Can't save the device. #{device.errors.messages}" }, 412) unless device.save
	    		device.pass_key_in_hash
      end
      
      #Request from mac : sends request to get the device with which it is paired
      #Needed when app launched in MAC
      get '/show' do
      	error!({ 'error' => "Mac Address Not Found" }, 412) unless params[:mac_address]
      	machine = Machine.where(:mac_address => params[:mac_address]).first
        #Returning token, host_name and pass_key
        error!({ 'error' => "You are not paired to any device." }, 412) unless machine
        machine.phone.in_hash# if machine
      end
      
      put '/reset' do
      	error!({ 'error' => "Token Not Found" }, 412) unless params[:new_token] and params[:old_token]
      	phone = ApnDevice.where(:token => params[:old_token]).first
      	error!({ 'error' => "Cant update the token." }, 412) unless phone and phone.update_attributes(:token => params[:new_token])
      	{ 'Response' => 'Token Changed' }
      end
      
    end #resource ApnDevice
    
    resource 'machines' do
      before { authenticate! }
		  #This method returns all machines paired with the device. ie: list of macs -- -- so they can be unpaired
		  #Request by device params[:token]

    	get '/index'	do
    		error!({ 'error' => "Device Token Not Found" }, 412) unless params[:token]
    		device = ApnDevice.where(:token => params[:token]).first || AndroidDevice.where(:token => params[:token]).first
#    		{ 'Response' => 'No Device' } if !device
    		error!({ 'Response' => "No Device" }, 412) unless device
  			"{\"machines\": #{device.machines.to_json}}"
#  			{ 'machines' => device.machines.to_json }
    	end
    	
      # Mac sends request to pair with an device. 
      # params -> Mac address and machine_name and 5-digit pass_key

			post '/create' do
			  error!({ 'error' => "Invalid Request" }, 412) unless (params[:mac_address] and params[:pass_key])
				device = ApnDevice.where(:pass_key => params[:pass_key]).first || AndroidDevice.where(:pass_key => params[:pass_key]).first
				if device
					machine = Machine.new(:mac_address => params[:mac_address], :machine_name => params[:machine_name] || "Mac")
#					machine.device = device
					machine.phone_id= device.id
					machine.phone_type = device.class.name
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
		  		machine = device.machines.where(:mac_address => params[:mac_address]).first if device
          error!({ 'error' => 'unpairing failed' }, 412) unless machine and machine.destroy # 412: Precondition Failed
#						device.machines  #Earlier response
						{ 'Response' => 'Unpairing Successful' }
		  	else
		  		machine = Machine.where(:mac_address => params[:mac_address]).first# unpaired from mac
		  		if machine and machine.destroy
#						machine.destroy #if destroy
						#Push notification to device
						machine.phone.notify_device( "#{machine.machine_name} unpaired." )
						{ 'Response' => 'Unpairing Successful' }
		  		else
		  			{ 'Response' => 'Machine already unpaired' }
		  		end
		  	end
		  end
		  
      # connect is for sending call or text request to the device.
      # params -> MAC address, tel, sms (optional) 
		  post '/connect' do
		  	error!({ 'error' => "Mac Address Not Found" }, 412) unless params[:mac_address]
		  	machine = Machine.where(:mac_address => params[:mac_address]).first
		  	error!({ 'error' => 'Cant connect' }, 401) unless machine && params[:tel]
				machine.phone.call_device(params[:tel], params[:sms])
				{ 'Response' => "Call Initiation Request Sent #{params[:sms]}" }
		  end
		  
		end #resource machine
    
  end #Class
end #Module
