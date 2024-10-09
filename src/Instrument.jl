using Sockets


struct Instrument
	address::String
	port::UInt16
	timeout::UInt16
	check::Symbol

	function Instrument(addr; port=5025, timeout=10, check=:none)
		port∈(0:65535) || throw(ArgumentError("port number must be in the range [0:65535]"))
		timeout∈(1:65535) || throw(ArgumentError("timeout must be in the range [1:65535] seconds"))
		check∈(:none,:opc,:err) || throw(ArgumentError("unknown check mode ':$check', must be ':none', ':opc' or ':err'"))
		new(addr,port,timeout,check)
	end
end


function Base.show(io::IO, inst::Instrument)
	print(io, "Instrument(\"$(inst.address)\", $(Int(inst.port)), timeout=$(Int(inst.timeout)), check=:$(inst.check))")
end


function (inst::Instrument)(message::AbstractString; kwargs...)
	(inst)(ScpiString(message); kwargs...)
end

function (inst::Instrument)(message::ScpiString; timeout=inst.timeout, check=inst.check)
	if check===:opc
		message = message * scpi"*OPC?"
	elseif check===:err
		message = scpi"*CLS" * message * scpi":SYSTEM:ERROR:NEXT?"
	end
	numq = numqueries(message)
	msg = message._str * "\n"
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
	
	write(socket,msg)
	
	if numq>0
		crd = Channel{String}(1)
		trd = @async begin put!(crd,readline(socket,keep=false)) end
		@async begin timedwait(()->istaskdone(trd),tout,pollint=1); put!(crd,"\n") end
		reply = take!(crd)
		close(crd)
		close(socket)
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
		else
			retval = response
		end
	else
		close(socket)
		retval = String[]
	end
	return retval
end

function (inst::Instrument)(::Type{String}, message; kwargs...)
	stringparse(inst(message; kwargs...))
end

function (inst::Instrument)(::Type{T}, message; kwargs...) where T<:Number
	numparse(T, inst(message; kwargs...))
end


function stringparse(sv::Vector{String})
	if length(sv)>1
		return replace.(sv, '"'=>"")
	elseif length(sv)>0
		str = sv[begin]
		iseven(count('"',str)) || error("unbalanced quotes in input string")
		maxlen = count(',', str)+1
		split_resp = Vector{String}(undef, maxlen)
		stridx = vecidx = 1
		quoted = false
		for (k,c) in enumerate(str)
			if c=='"'
				quoted = !quoted
			elseif !quoted && c==','
				if k-1-stridx>0
					split_resp[vecidx] = str[stridx:k-1]
					vecidx += 1
				end
				stridx = k+1
			end
		end
		if length(str)-1-stridx>0
			split_resp[vecidx] = str[stridx:length(str)-1]
			vecidx += 1
		end
		split_resp = replace.(split_resp[begin:vecidx-1], '"'=>"")
		if length(split_resp)>1
			return split_resp
		elseif length(split_resp)>0
			return split_resp[begin]
		else
			return nothing
		end
	else
		return nothing
	end
end


function numparse(::Type{T}, sv::Vector{String}) where T<:Number
	if length(sv)>1
		return parse.(T, sv)
	elseif length(sv)>0
		split_str = split(sv[begin], ',')
		if any(isempty, split_str)
			return nothing
		end
		split_resp = parse.(T, split_str)
		if length(split_resp)>1
			return split_resp
		elseif length(split_resp)>0
			return split_resp[begin]
		else
			return nothing
		end
	else
		return nothing
	end
end
