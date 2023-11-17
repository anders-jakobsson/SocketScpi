using Sockets


struct Instrument
	_address::String
	_port::UInt16
	_timeout::UInt16
	#TODO Add default verification method

	function Instrument(addr; port=5025, timeout=10)
		port∈(0:65535) || error("Port number must be in the range [0:65535]")
		timeout∈(1:65535) || error("Timeout must be in the range [1:65535] seconds")
		new(addr,port,timeout)
	end
end

function Base.propertynames(::Instrument, private::Bool=false)
	if private
		return (:_address,:_port,:_timeout)
	else
		return ()
	end
end


# Custom pretty-printing.
function Base.show(io::IO, inst::Instrument)
	print(io, "Instrument($(inst._address), $(Int(inst._port)), $(Int(inst._timeout)))")
end



"""
    (inst::Instrument)(command) -> Vector{String}

Send `command` to the instrument `inst`. `command` may be either an `AbstractString` or 
a `ScpiString`. If `command` contains any query, the reply is read back from the instrument.
 
"""
(inst::Instrument)(command::AbstractString; timeout=0) = (inst)(ScpiString(command), timeout=timeout)
function (inst::Instrument)(command::ScpiString; timeout=0)
	cmd = command._str * "\n"
	# tout = timeout>0 ? UInt16(timeout) : inst._timeout
	# cwr = Channel{Bool}(1)
	# twr = @async begin println("Connecting");connect(socket,inst._address,inst._port); put!(cwr,true); print("Connected") end
	# @async begin timedwait(()->istaskdone(twr),tout,pollint=1)==:ok || put!(cwr,false) end
	# println("Waiting for connection")
	# connected = take!(cwr)
	# println("Connected")
	# close(cwr)
	# if !connected
	# 	throw(TimeoutException("Could not connect to $(inst._address) on port $(inst._port) since the operation timed out after $(tout) seconds"))
	# end

	tout = timeout>0 ? UInt16(timeout) : inst._timeout
	socket = TCPSocket()
	timer = Timer(_->close(socket), tout)
	try
		connect(socket, inst._address, inst._port)
	catch err
		if isa(err, Base.IOError)
			rethrow()
		else
			throw(TimeoutException("Could not connect to $(inst._address) on port $(inst._port) since the operation timed out after $(tout) seconds"))
		end
	finally
		close(timer)
	end
	
	write(socket,cmd)
	
	if hasquery(command)
		crd = Channel{String}(1)
		trd = @async begin put!(crd,readline(socket,keep=false)) end
		@async begin timedwait(()->istaskdone(trd),tout,pollint=1); put!(crd,"\n") end
		reply = take!(crd)
		close(crd)
		if reply=="\n"
			throw(TimeoutException("Could not read from instrument at $(inst._address) on port $(inst._port) since the operation timed out after $(tout) seconds"))
		end
		retval = String.(split(reply,';',keepempty=true))
	else
		retval = String[]
	end
	close(socket)
	return retval
end


function (inst::Instrument)(t::Type, command)
	conv_fun = _conversion_function(t)
	response = inst(command)
	if length(response)>1
		return conv_fun.(response)
	elseif length(response)>0
		return conv_fun(response[begin])
	else
		return nothing
	end
end


_conversion_function(::Type{T}) where T<:Number = x->parse(T, x)
