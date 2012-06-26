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
    
    resource 'apn_devices' do
      # before { authenticate! } # added to each resource for skipping un-authorized access

    	#Below method returns the randomly* generated pass_key in valid json format
    	#Scenario : iPhone sends post request for pairing
    	#params[:token]
    	#Optional params => host_name
    	post 'create' do
      	device = ApnDevice.find_by_token(params[:token])
      	if device
      	  {'response' => true}
      	else
        	device = ApnDevice.new(:host_name=>params[:host_name], :token=>params[:token], :app_id=>1 )
        	device.pass_key = (rand(0.0)*100000).to_i
        	device.pass_key_in_hash if device.save      	  
    	  end
      end
      
      #Request from mac : sends request to get the iPhone with which it is paired
      #Needed when app launched in MAC
      get '/show' do
      	machine = Machine.find_by_mac_address params[:mac_address]
        machine.apn_device if machine
      end
      
    end   #resource ApnDevice
    

    resource 'machines' do
  	  #This method returns all machines paired with the iPhone. ie: list of macs--
  	  # --so they can be unpaired
  	  #Request by iPhone params[:token]
    	get '/show'	do
    		iPhone = ApnDevice.find_by_token(params[:token])
    		iPhone.machines if iPhone
    	end
    	
#    	Mac sends request to pair with an iPhone. 
#    	params -> Mac address and pass_key and machine_name

			post '/create' do
				iPhone = ApnDevice.find_by_pass_key(params[:pass_key])
				if iPhone
					machine = Machine.new(:mac_address => params[:mac_address], :machine_name => params[:machine_name]) 
					machine.apn_device_id = iPhone.id
					if machine.save
						iPhone.update_attributes(:pass_key => nil)
						#push notification to iPhone
					end
				else
#					send error message to MAC for invalid pass_key
          error!({ 'error' => 'invalid pass_key', 'params' => params[:pass_key] }, 401)
				end
			end
			
			#unpairing from MAC Or iPhone
			delete do
		  	if params[:token]   #unpairing from iPhone
		  		iPhone = ApnDevice.find_by_token params[:token]
		  		if iPhone && Machine.where(:apn_device_id => iPhone.id).first #machine belongs to that iPhone from which request came 
		  			Machine.find_by_mac_address(params[:mac_address]).destroy
		  			## send list of leftout machines paired with this iPhone (json)
		  		end
		  	else  #unpairing from MAC
		  		Machine.find_by_mac_address(params[:mac_address]).destroy
		  		#Push notification to iPhone
		  	end
		  end
		  
		end #resource Machine
    
  end #Class
end #Module
