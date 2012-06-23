require 'apn_on_rails'
module PushDialer
  class API < Grape::API
  	format :json
  	default_format :json
    prefix 'api'
    resource 'apn_devices' do
    	#Below method returns the randomly* generated pass_key in valid json format
    	#Scenario : iPhone sends post request for pairing
    	#params[:token]
    	#Optional params => host_name
    	post 'create' do
      	device = ApnDevice.find_by_token(params[:token])
      	device = ApnDevice.new(:host_name=>params[:host_name], :token=>params[:token], :app_id=>1 ) if !device
      	device.pass_key = (rand(0.0)*100000).to_i
      	"{\"pass_key\":#{device.pass_key}}" if device.save
      end
      
#Request from mac : sends request to get the iPhone with which it is paired
#Needed when app launched in MAC
      get '/show' do
      	machine = Machine.find_by_mac_address params[:mac_address]
        ApnDevice.find(machine.apn_device_id) if machine
      end
      
    end#resource ApnDevice
    resource 'machines' do
    
		  #This method returns all machines paired with the iPhone. ie: list of macs--
		  # --so they can be unpaired
		  #Request by iPhone params[:token]
    	get '/show'	do
    		iPhone = ApnDevice.find_by_token(params[:token])
    		Machine.where(:apn_device_id => iPhone.id) if iPhone
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
				end
			end
			
			#unpairing from MAC Or iPhone
			delete do
		  	if params[:token] #unpairing from iPhone
		  		iPhone = ApnDevice.find_by_token params[:token]
		  		if iPhone && Machine.where(:apn_device_id => iPhone.id).first #machine belongs to that iPhone from which request came 
		  			Machine.find_by_mac_address(params[:mac_address]).destroy
		  		end
		  	else
		  		Machine.find_by_mac_address(params[:mac_address]).destroy
		  		#Push notification to iPhone
		  	end
		  end
		  
		end#resource machine
    
  end #Class
end #Module
