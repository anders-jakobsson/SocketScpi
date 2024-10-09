module SocketScpi

export ScpiString, Instrument, @scpi_str, hasquery, numqueries, stringparse, numparse, ScpiNode
include("Exceptions.jl")
include("ScpiString.jl")
include("Instrument.jl")
include("ScpiNode.jl")
include("Documentation.jl")

end
