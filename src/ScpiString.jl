
"""
    ScpiString

Type representing a SCPI command or set of commands.
"""
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


"""
    ScpiString(xs...)

Return an ScpiString built from `xs`. Equivalent to `scpi"SomeCommandText"`.

The input string `xs` is pre-procecced and validated. In case of additional string
arguments, each is converted to an `ScpiString` and then concatenated as sub-commands, 
see . Every argument may also contain multiple sub-commands 
on their own. Note that while a SCPI command is terminated with a newline '\n', it is not 
neccessary to terminate `xs` with a newline as this will be added automatically when sending
the command. In fact, any leading or trailing newline or whitespace will be removed by the
constructor. At the same time, no newline character is allowed within a command.

# Examples
```julia-repl
julia> ScpiString("*IDN?")
SCPI string with one command of which one is a query
 *IDN?
```
```julia-repl
julia> ScpiString(":FREQ:CENT 1GHz", "SPAN 100MHz", ":INIT:CONT?", ":TRAC:CLE ALL")
SCPI string with 4 commands of which one is a query
 :FREQ:CENT 1GHz
       SPAN 100MHz
 :INIT:CONT?
 :TRAC:CLE ALL
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

See also [`^(::ScpiString,::ScpiString)`](@ref)
"""
Base.:*(x::ScpiString, y::ScpiString...) = ScpiString(join(vcat(x._str,[s._str for s in y]), ';'))
Base.:*(x::AbstractString, y::ScpiString) = *(promote(x,y)...)
Base.:*(x::ScpiString, y::AbstractString) = *(promote(x,y)...)


"""
	^(x::ScpiString, y::Integer) -> ScpiString
	x ^ y -> ScpiString

Repeat SCPI command `x` `y` times by concatenation.

See also [`*(::ScpiString,::ScpiString...)`](@ref)
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


"""
    numqueries(x::ScpiString) -> Int

Return the number of queries in `x`.
"""
numqueries(s::ScpiString) = count('?', x._str)


"""
    validate(s::ScpiString)
	validate(s::AbstractString)
	validate(ls::AbstractVector{<:AbstractString})

Validate the format of `s` and return an error message if invalid, or an empty string if valid. If multiple 
errors exist in the string, only the first error is returned.
"""
validate(s::ScpiString) = validate(s._str)
function validate(s::AbstractString)
	for cmd in _split_cmd(s)
		isascii(cmd) || return("non-ASCII character(s) found in command '$cmd'")
		contains(cmd, r"\W\?") && return("a question mark preceeded by a non-word character found in command '$cmd'")
	end
	return("")
end




# Internal functions --------------------------------------------------------------------------------------------------

_split_cmd(s::ScpiString) = _split_cmd(s._str)
_split_cmd(s::AbstractString) = split(s, ';', keepempty=false)
