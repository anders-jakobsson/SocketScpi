
"""
    ScpiString

Type representing a SCPI command or set of commands.
"""
struct ScpiString
	_str::String

	function ScpiString(str::AbstractString)
		isascii(str) || error("The string may only contain ASCII characters")
		splitstr = filter(s->length(s)>0, strip.(split(str, ';', keepempty=false)))
		if length(splitstr)<1
			error("No valid command found in the input string")
		end
		#TODO Check validity of sub-commands, when such a function has been implemented
		new(join(splitstr, ";"))
	end
end


"""
    ScpiString(xs...)

Return an ScpiString built from `xs`. Equivalent to `scpi"SomeCommandText"`.

If multiple arguments are given, they are concatenated as sub-commands by separating 
them with a semicolon. Empty sub-commands are removed, and leading/trailing whitespace
is trimmed from each sub-command.

# Examples
```julia-repl
julia> ScpiString("*IDN?")
scpi"*IDN?"
```
```julia-repl
julia> ScpiString(":FREQ:CENT 1MHz", "\\n;CENT?", "*OPC?")
scpi":FREQ:CENT 1MHz;CENT?;*OPC?"
```
"""
ScpiString(xs...) = prod(ScpiString.(xs))




# Macros --------------------------------------------------------------------------------------------------------------
"""
	scpi"<command>"

Create a ScpiString object from a string. 
"""
macro scpi_str(str)
	return ScpiString(unescape_string(str))
end




# Printing ------------------------------------------------------------------------------------------------------------
function Base.show(io::IO, s::ScpiString)
	compact = get(io, :compact, false)
	_print_one_line(io, s, compact)
end

function Base.show(io::IO, ::MIME"text/plain", s::ScpiString)
	cmds = split(s._str, ';', keepempty=false)
	numc = length(cmds)
	numq = count('?', s._str)
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




# Conversion & Promotion ----------------------------------------------------------------------------------------------
Base.convert(::Type{ScpiString}, x::AbstractString) = ScpiString(x)
Base.promote_rule(::Type{<:AbstractString}, ::Type{ScpiString}) = ScpiString




# Operators -----------------------------------------------------------------------------------------------------------
"""
    *(x::ScpiString, y::AbstractString) -> ScpiString
    *(x::AbstractString, y::ScpiString) -> ScpiString
    x * y -> ScpiString

Concatenate two SCPI strings, or a SCPI string and an AbstractString. A semicolon will automatically be added between
the strings.

See also [`^()`](@ref)
"""
Base.:*(x::AbstractString, y::ScpiString) = *(promote(x,y)...)
Base.:*(x::ScpiString, y::AbstractString) = *(promote(x,y)...)
Base.:*(x::ScpiString, y::ScpiString) = ScpiString(string(x._str,";",y._str))


"""
	^(x::ScpiString, y::Integer) -> ScpiString
	x ^ y -> ScpiString

Repeat SCPI command `x` `y` times by concatenation.

See also [`*()`](@ref)
"""
Base.:^(x::ScpiString, y::Integer) = ScpiString(join(fill(x._str,y), ";"))




# Iterate implementation ----------------------------------------------------------------------------------------------
Base.iterate(s::ScpiString) = iterate(_split_cmd(s))
Base.iterate(s::ScpiString, state::Int) = iterate(_split_cmd(s), state)
Base.length(s::ScpiString) = length(_split_cmd(s))
Base.eltype(::Type{ScpiString}) = SubString{String}




# Misc. functions -----------------------------------------------------------------------------------------------------
"""
    hasquery(x::ScpiString) -> Bool

Return `true` if `x` contains at least one query, i.e., a command containing a '?'.
"""
hasquery(s::ScpiString) = '?' ∈ s._str




# Internal functions --------------------------------------------------------------------------------------------------

_split_cmd(s::ScpiString) = split(s._str, ';', keepempty=false)


function _print_one_line(io, s, compact)
	if compact
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