"""
	SocketScpi

Support for sending SCPI commands to an instrument over a TCP socket.

"""
module SocketScpi

export ScpiString, Instrument, @scpi_str, hasquery
include("Exceptions.jl")
include("ScpiString.jl")
include("Instrument.jl")

end
