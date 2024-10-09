
struct ScpiString
	_str::String

	function ScpiString(str::AbstractString)
		splitstr = filter(s->length(s)>0, strip.(_split_cmd(str)))
		length(splitstr)>0 || error("no command found in the input string")
		errstr = validate(str)
		isempty(errstr) || error(errstr)
		new(join(splitstr, ";"))
	end
end

function ScpiString(xs::Union{ScpiString,AbstractString}...)
	length(xs)>0 || error("no input string")
	prod(ScpiString.(xs))
end

ScpiString(str::ScpiString) = ScpiString(str._str)




# Macros -----------------------------------------------------------------------------------
macro scpi_str(str)
	return ScpiString(unescape_string(str))
end




# Printing ---------------------------------------------------------------------------------
function Base.show(io::IO, s::ScpiString)
	if get(io, :compact, false)
		maxlength = displaysize(io)[2] - 10
		if length(s._str)<=maxlength
			print(io, s._str)
		else
			idx = findfirst(';', s._str)
			if isnothing(idx)
				idx = maxlength-3
			elseif idx<=maxlength-3
				while true
					nextidx = findnext(';', s._str, idx+1)
					if isnothing(nextidx) || nextidx>maxlength-3
						break
					end
					idx = nextidx
				end
			end
			print(io, s._str[1:idx]*"...")
		end
	else
		print(io, "scpi\"$(s._str)\"")
	end
end

function Base.show(io::IO, ::MIME"text/plain", s::ScpiString)
	cmds = _split_cmd(s)
	numc = length(cmds)
	numq = numqueries(s)
	@assert numc>0
	cstr = numc>1 ? "$numc commands" : "one command"
	qstr = numq>1 ? "$numq are queries" : numq>0 ? "one is a query" : "none are queries"
	print(io, "SCPI string with $cstr of which $qstr")
	rlvl = 1
	for cmd in cmds
		if startswith(cmd, (':','*'))
			rlvl = 1
		end
		print(io, "\n"*" "^rlvl*cmd)
		m = match(r"^(:?(?:\w+:)+)\w+"a, cmd)
		rlvl = isnothing(m) ? rlvl : rlvl+length(m.captures[1])
	end
end




# Conversion & Promotion -------------------------------------------------------------------
Base.convert(::Type{ScpiString}, x::AbstractString) = ScpiString(x)
Base.promote_rule(::Type{<:AbstractString}, ::Type{ScpiString}) = ScpiString




# Operators --------------------------------------------------------------------------------
Base.:*(x::ScpiString, y::ScpiString...) = ScpiString(join(vcat(x._str,[s._str for s in y]), ';'))
Base.:*(x::AbstractString, y::ScpiString) = *(promote(x,y)...)
Base.:*(x::ScpiString, y::AbstractString) = *(promote(x,y)...)
Base.:^(x::ScpiString, y::Integer) = ScpiString(join(fill(x._str,y), ";"))




# Iterate implementation -------------------------------------------------------------------
Base.iterate(s::ScpiString) = iterate(_split_cmd(s))
Base.iterate(s::ScpiString, state::Int) = iterate(_split_cmd(s), state)
Base.length(s::ScpiString) = length(_split_cmd(s))
Base.eltype(::Type{ScpiString}) = SubString{String}




# Misc. functions --------------------------------------------------------------------------
hasquery(s::ScpiString) = '?' ∈ s._str
numqueries(s::ScpiString) = count('?', s._str)
validate(s::ScpiString) = validate(s._str)

function validate(s::AbstractString)
	for cmd in _split_cmd(s)
		isascii(cmd) || return("non-ASCII character(s) found in command '$cmd'")
		contains(cmd, r"\W\?") && return("a question mark preceeded by a non-word character found in command '$cmd'")
	end
	return("")
end




# Internal functions -----------------------------------------------------------------------
_split_cmd(s::ScpiString) = _split_cmd(s._str)
_split_cmd(s::AbstractString) = split(s, ';', keepempty=false)
