using Sockets


"""
	Instrument

Type encapsulating an SCPI-capable instrument.

# Fields
	address::String    IPv4/IPv6 address string
	port::UInt16       port number
	timeout::UInt16    timeout in seconds
	check::Symbol      verification method, `:none`, `:opc` or `:err`


"""
struct Instrument
	address::String
	port::UInt16
	timeout::UInt16
	check::Symbol

	"""
		Instrument(addr; port=5025, timeout=10, check=:none)
	
	Return an `Instrument` object with the given address, port, timeout and verification
	method.

	# Example
	```julia-repl
	inst = Instrument("192.168.0.83", port=5025, timeout=3, check=:opc)
	Instrument("192.168.0.83", 5025, timeout=3, check=:opc)
	```
	"""
	function Instrument(addr; port=5025, timeout=10, check=:none)
		port∈(0:65535) || throw(ValueError("port number must be in the range [0:65535]"))
		timeout∈(1:65535) || throw(ValueError("timeout must be in the range [1:65535] seconds"))
		check∈(:none,:opc,:err) || throw(ValueError("unknown check mode ':$check', must be ':none', ':opc' or ':err'"))
		new(addr,port,timeout,check)
	end
end


# Custom pretty-printing.
function Base.show(io::IO, inst::Instrument)
	print(io, "Instrument(\"$(inst.address)\", $(Int(inst.port)), timeout=$(Int(inst.timeout)), check=:$(inst.check))")
end



"""
	(inst::Instrument)(message; timeout=inst.timeout, check=inst.check) -> Vector{String}

Send `message` to `inst`. `message` may be either an `AbstractString` or a `ScpiString`. 
If `message` contains any query, read back the reply from the instrument. Return a vector 
of strings with one element for each query. Throws a `TimeoutException` if a timeout 
occurs while connecting or reading from the instrument.

The optional `timeout` and `check` arguments allows overriding the default timeout and
verification methods of `inst`. If `check=:opc`, an '*OPC?' (operation completed) query
will be appended to `message`. The instrument will only reply to this query when all 
pending operations are complete, hence this function will only return when all operations
are complete, or the operation times out. The result of the '*OPC?' query is stripped from
the return value. 

# Examples
```julia-repl
julia> inst("SYSTEM:CAPABILITY?; :OUTPUT:STATE?")
2-element Vector{String}:
 "\\"DCSUPPLY WITH (MEASURE|MULTIPLE|TRIGGER)\\""
 "0"
```
"""
(inst::Instrument)(message::AbstractString; kwargs...) = (inst)(ScpiString(message); kwargs...)

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


"""
	(inst::Instrument)(String, message::ScpiString; kwargs...)

Call `inst(message; kwargs...)` and then call `stringparse` on the result.
"""
function (inst::Instrument)(::Type{String}, message; kwargs...)
	stringparse(inst(message; kwargs...))
end


"""
	(inst::Instrument)(T, message::ScpiString; kwargs...) where T<:Number

Call `inst(message; kwargs...)` and then call `numparse` on the result.
"""
function (inst::Instrument)(::Type{T}, message; kwargs...) where T<:Number
	numparse(inst(message; kwargs...))
end




"""
	stringparse(sv::Vector{String})

Attempt to parse `sv` as a vector of quoted strings, return a string or vector of strings.

The behavior depends on the length of `sv` and the contents of each element.

* If `sv` has multiple elements, return `sv` with escaped double quotes removed. 
* If `sv` has one element, try to split the element at non-quoted commas. \
  If the result has more than one element, return it as is. Otherwise, return \
  the first element. Throw an error if the number of escaped double quotes is odd.
* If `sv` is empty, return `nothing`.

# Examples
```julia-repl
julia> stringparse(["\\"A message\\""])
"A message"

julia> stringparse(["\\"String1\\"", "\\"Sub-string2-1, Sub-string2-2\\"", "\\"String3\\""])
3-element Vector{String}:
 "String1"
 "Sub-string2-1, Sub-string2-2"
 "String3"

 julia> stringparse(["\\"String1\\",\\"Sub-string2-1, Sub-string2-2\\",\\"String3\\""])
3-element Vector{String}:
 "String1"
 "Sub-string2-1, Sub-string2-2"
 "String3"
```
Note that non-quoted strings are also returned.
```julia-repl
julia> stringparse(["1", "\\"A message\\""])
2-element Vector{String}:
 "1"
 "A message"
```
"""
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
		else
			return split_resp[begin]
		end
	else
		return nothing
	end
end




"""
	numparse(T, sv::Vector{String}) where T<:Number

Attempt to parse the content of `sv` as numbers of type `T`, return a number or vector of 
numbers. Throw an error if parsing fails.

The behavior depends on the length of `sv` and the contents of each element.

* If `sv` has multiple elements, try to parse each element as a number of type `T`. 
* If `sv` has one element, split the element at every comma. \
  If the result has more than one element, parse and return that vector. Otherwise, \
  parse and return the first element. 
* If `sv` is empty, return `nothing`.

# Examples
```julia-repl
julia> numparse(Int, ["1", "2", "3"])
3-element Vector{Int64}:
1
2
3
```
```julia-repl
julia> numparse(Float64, ["-0.5, 0.0, +0.5"])
3-element Vector{Float64}:
 -0.5
  0.0
  0.5
```
"""
function numparse(::Type{T}, sv::Vector{String}) where T<:Number
	if length(sv)>1
		return parse.(T, sv)
	elseif length(sv)>0
		split_resp = parse.(T, split(sv[begin], ','))
		if length(split_resp)>1
			return split_resp
		else
			return split_resp[begin]
		end
	else
		return nothing
	end
end
