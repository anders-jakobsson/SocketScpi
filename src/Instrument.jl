using Sockets


struct Instrument
	address::String
	port::UInt16
	timeout::UInt16
	check::Symbol

	function Instrument(addr; port=5025, timeout=10, check=:none)
		port∈(0:65535) || error("port number must be in the range [0:65535]")
		timeout∈(1:65535) || error("timeout must be in the range [1:65535] seconds")
		check∈(:none,:opc,:err) || error("unknown check mode ':$check', must be ':none', ':opc' or ':err'")
		new(addr,port,timeout,check)
	end
end


# Custom pretty-printing.
function Base.show(io::IO, inst::Instrument)
	print(io, "Instrument(\"$(inst.address)\", $(Int(inst.port)), timeout=$(Int(inst.timeout)), check=:$(inst.check))")
end



"""
    (inst::Instrument)(command) -> Vector{String}

Send `command` to `inst`. `command` may be either an `AbstractString` or a `ScpiString`. 
If `command` contains any query, read back the reply from the instrument. Return a vector 
of all reply strings, or an empty `String` vector if no queries. An element of the return
vector may be a comma separated list of values, 

If the optional type argument is given, then further process the output. First of all,
if there are no queries, return `nothing` instead of an empty vector. If exactly one 
query, return a scalar instead of a one-element vector. Second, convert the result(s)
to the given type. Throw an error unless all queries can be converted to `Type`. 

	* String: 

# Examples
```julia-repl
inst("SYSTEM:CAPABILITY?; :OUTPUT:STATE?")
2-element Vector{String}:
 "\"DCSUPPLY WITH (MEASURE|MULTIPLE|TRIGGER)\""
 "0"
```
"""
(inst::Instrument)(command::AbstractString; timeout=0) = (inst)(ScpiString(command), timeout=timeout)

function (inst::Instrument)(command::ScpiString; timeout=inst.timeout, check=inst.check)
	if check===:opc
		command = command*"*OPC?"
	elseif check===:err
		command = "*CLS"*command*":SYSTEM:ERROR:CODE:NEXT?"
	end
	cmd = command._str * "\n"
	numq = numqueries(cmd)
	# tout = timeout>0 ? UInt16(timeout) : inst._timeout
	# cwr = Channel{Bool}(1)
	# twr = @async begin println("Connecting");connect(socket,inst._address,inst._port); put!(cwr,true); print("Connected") end
	# @async begin timedwait(()->istaskdone(twr),tout,pollint=1)==:ok || put!(cwr,false) end
	# println("Waiting for connection")
	# connected = take!(cwr)
	# println("Connected")
	# close(cwr)
	# if !connected
	# 	throw(TimeoutException("Could not connect to $(inst.address) on port $(inst.port) since the operation timed out after $(tout) seconds"))
	# end

	tout = UInt16(timeout)
	socket = TCPSocket()
	timer = Timer(_->close(socket), tout)
	try
		connect(socket, inst.address, inst.port)
	catch err
		if isa(err, Base.IOError)
			rethrow()
		else
			throw(TimeoutException("Could not connect to $(inst.address) on port $(inst.port) since the operation timed out after $(tout) seconds"))
		end
	finally
		close(timer)
	end
	
	write(socket,cmd)
	
	if numq>0
		crd = Channel{String}(1)
		trd = @async begin put!(crd,readline(socket,keep=false)) end
		@async begin timedwait(()->istaskdone(trd),tout,pollint=1); put!(crd,"\n") end
		reply = take!(crd)
		close(crd)
		if reply=="\n"
			throw(TimeoutException("Could not read from instrument at $(inst.address) on port $(inst.port) since the operation timed out after $(tout) seconds"))
		end
		response = String.(split(reply,';',keepempty=true))
		numr = length(response)
		numr==numq || error("instrument returned $numr responses, $numq expected")
		if check===:opc
			response[end]=="1" || error("instrument failed to return a '1' to the *OPC query")
			retval = response[begin:end-1]
		elseif check===:err
			errno,errmsg = split(response[end], ',')
			errno=="0" || error("verification error: '$errmsg'")
			retval = response[begin:end-1]
		end
	else
		retval = String[]
	end
	close(socket)
	return retval
end

function (inst::Instrument)(::Type{String}, command)
	response = inst(command)
	if length(response)>1
		return strip.(response, '\"')
	elseif length(response)>0
		return strip(response[begin], '\"')
	else
		return nothing
	end
end

function (inst::Instrument)(::Type{T}, command) where T<:Number
	response = inst(command)
	if length(response)>1
		return parse.(T, response)
	elseif length(response)>0
		return parse(T, response[begin])
	else
		return nothing
	end
end

function (inst::Instrument)(::Type{Vector{T}}, command) where T<:Number
	response = inst(command)
	length(response)<2 || error("a maximum of one query is allowed when converting to an array")
	if length(response)>0
		',' in response[begin] || error("no vector data found in response string")
		parse.(T, split(response[begin], ','))
	else
		return nothing
	end
end
