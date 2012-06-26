class APN::Device < APN::Base
	  validates_format_of :token, :with => /^(.)+{10}$/
end
