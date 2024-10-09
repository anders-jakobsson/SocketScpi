using SocketScpi
using Test

@testset "SocketScpi.jl" begin

	@testset "ScpiString tests" begin
		include("scpistring_tests.jl")
	end

	@testset "Insrument tests" begin
		include("instrument_tests.jl")
	end

end