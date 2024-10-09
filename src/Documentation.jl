# This file contains all user-facing documentation of the module*, i.e., all exported types,
# functions, macros etc. For documentation of unexported functions and other developer 
# information, please see the relevant chapters in the help files, as well as code comments
# inside the functions.
#  *With the exception of constructors which currently need to be defined localy. This is 
# because docstrings are associated to a name, and types and their constructors share name.


# ------------------------------------------------------------------------------------------
# Modules

"""
Introduction
============

SocketScpi is a Julia package that enables 
[SCPI](https://www.ivifoundation.org/docs/scpi-99.pdf) communication with an instrument,
allowing you to control and query the instrument for data. SocketScpi communicates with the
instrument using TCP sockets. By relying on 
Julia [Sockets](https://docs.julialang.org/en/v1/stdlib/Sockets/) from the standard library, 
no additional drivers (for example VISA) are needed.

Communication is base on the following two concepts

* Instrument
* ScpiString

`Instrument` is an object that encapsulates the properties needed to communicate with an 
instrument. This includes its address and port, as well as default timeout. An `Instrument` 
object is callable. Instrument communication is performed by calling the object with a 
`ScpiString`. A `ScpiString` is a string that is formated as a SCPI command. A command can 
be made up of multiple sub-commands separated by semicolons.

Installation
------------

Note! This package is not yet official, and must be installed from its GitHub repository.
To do this, do the following:

```julia-repl
julia> using Pkg
julia> Pkg.add("https://github.com/anders-jakobsson/SocketScpi/tree/main")
```

Usage
-----

Setting up instrument communication is quite simple. First, create an `Instrument` object 
for each instrument, for example:

```julia-repl
julia> using SocketScpi
julia> spec = Instrument("192.168.0.56", port=5025, timeout=5)
Instrument("192.168.0.56", 5025, timeout=5, check=:none)
```

The `port` and `timeout` arguments are optional, and default to `5025` and `10` 
respectively. For additional information, please see 
[The Instrument type](#the-instrument-type) section. Once an `Instrument` object has been 
created, simply __call__ the object with the SCPI command string as in:

```julia-repl
julia> spec(":FREQUENCY:CENTER 1GHz")
```

So in summary, you can have instrument communication up and running with just three lines 
of code.
"""
SocketScpi




# ------------------------------------------------------------------------------------------
# Types

"""
	Instrument

Type encapsulating an SCPI-capable instrument.

# Fields
	address::String    IPv4/IPv6 address string
	port::UInt16       port number
	timeout::UInt16    default timeout in seconds
	check::Symbol      default verification method, `:none`, `:opc` or `:err`
"""
Instrument


@doc """
	Instrument(addr; port=5025, timeout=10, check=:none)

Return an `Instrument` object with the given address, port, timeout and verification
method.

# Example
```julia-repl
inst = Instrument("192.168.0.83", port=5025, timeout=3, check=:opc)
Instrument("192.168.0.83", 5025, timeout=3, check=:opc)
```
"""
Instrument(::Any)


"""
    ScpiString

Type representing a SCPI message.
"""
ScpiString


@doc """
	ScpiString(xs...)

Return an ScpiString built from `xs`. Equivalent to `scpi"SomeText"`.

The input string `xs` is pre-procecced and validated. In case of additional string
arguments, each is converted to an `ScpiString` and then concatenated, see TODO. Note that 
while a SCPI message is terminated with a newline '\n', it is not 
neccessary to terminate `xs` with a newline as this will be added automatically when sending
the message. In fact, any leading or trailing newline or whitespace will be removed by the
constructor. At the same time, no newline character is allowed within a message.

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
ScpiString(::AbstractString...)



# ------------------------------------------------------------------------------------------
# Functions

"""
	(inst::Instrument)([type,] message; timeout=inst.timeout, check=inst.check)

Send `message` to `inst`. `message` may be either an `AbstractString` or a `ScpiString`. 
If `message` contains any query, read back the reply from the instrument. Return a vector 
of strings with one element for each query. Throws a `TimeoutException` if a timeout 
occurs while connecting or reading from the instrument.

The optional type argument allows for direct conversion of the query result. 
If `type==String`, `stringparse` is called on the result. If `type<:Number`, `numparse` is 
called.

The optional `timeout` and `check` arguments allows overriding the default timeout and
verification methods of `inst`. If `check=:opc`, an `*OPC?` (operation completed) query
will be appended to `message`. The instrument will only reply to this query when all 
pending operations are complete, hence this function will only return when all operations
are complete, or the operation times out. The result of the `*OPC?` query is stripped from
the return value.

# Examples
```julia-repl
julia> inst("SYSTEM:CAPABILITY?; :OUTPUT:STATE?")
2-element Vector{String}:
 "\\"DCSUPPLY WITH (MEASURE|MULTIPLE|TRIGGER)\\""
 "0"
```

See also [`stringparse`](@ref), [`numparse`](@ref)
"""
function (::Instrument)(::ScpiString, ::Any...) end



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
stringparse




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

julia> numparse(Float64, ["-0.5, 0.0, +0.5"])
3-element Vector{Float64}:
 -0.5
  0.0
  0.5
```
"""
numparse




"""
    *(x::ScpiString, y::AbstractString) -> ScpiString
    *(x::AbstractString, y::ScpiString) -> ScpiString
    x * y -> ScpiString

Concatenate two SCPI strings, or a SCPI string and an AbstractString. A semicolon will 
automatically be added between the strings.
"""
Base.:*




"""
	^(x::ScpiString, y::Integer) -> ScpiString
	x ^ y -> ScpiString

Repeat SCPI message `x` for `y` times by concatenation.
"""
^




"""
    hasquery(x::ScpiString) -> Bool

Return `true` if `x` contains at least one query, i.e., a message containing a '?'.
"""
hasquery




"""
    numqueries(x::ScpiString) -> Int

Return the number of queries in `x`.
"""
numqueries




"""
    validate(s::ScpiString)
	validate(s::AbstractString)

Validate the format of `s` and return an error message if invalid, or an empty string if 
valid. If multiple errors exist in the string, only the first error is returned.
"""
validate




# ------------------------------------------------------------------------------------------
# Macros

"""
	scpi"<message>"

Create a ScpiString object from a string. 
"""
scpi_str