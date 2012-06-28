class ApplicationController < ActionController::Base
  protect_from_forgery
  
  rescue_from Exception, :with => :redirect_to_home
  
  def redirect_to_home
    redirect_to root_path
  end
	
end
