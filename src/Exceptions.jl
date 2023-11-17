struct TimeoutException <: Exception 
	msg::String
end

Base.showerror(io::IO, err::TimeoutException) = print(io, "TimeoutException: $(err.msg)")