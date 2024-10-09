@testset "Construction" begin
	@test typeof(Instrument("0.0.0.0")) == Instrument
	@test typeof(Instrument("0.0.0.0";port=5,timeout=5,check=:opc)) == Instrument
	@test_throws ArgumentError Instrument("0.0.0.0";port=-1)
	@test_throws ArgumentError Instrument("0.0.0.0";timeout=0)
	@test_throws ArgumentError Instrument("0.0.0.0";check=:log10)
	@test repr(Instrument("0.0.0.0")) == "Instrument(\"0.0.0.0\", 5025, timeout=10, check=:none)"
end

@testset "Parsing" begin
	@test isnothing(stringparse(String[]))
	@test isnothing(stringparse([""]))
	@test stringparse(["\"A message\""]) == "A message"
	@test stringparse(["\"String1\"", "\"Sub-string2-1, Sub-string2-2\"", "\"String3\""]) ==
		["String1", "Sub-string2-1, Sub-string2-2", "String3"]
	@test stringparse(["\"String1\",\"Sub-string2-1, Sub-string2-2\",\"String3\""]) == 
		["String1", "Sub-string2-1, Sub-string2-2", "String3"]
	
	@test isnothing(numparse(Int, String[]))
	@test isnothing(numparse(Int, [""]))
	@test numparse(Int, ["1","2","3"]) == [1,2,3]
	@test numparse(Float64, ["-0.5, 0.0, +0.5"]) ≈ [-0.5, 0.0, 0.5]
	@test numparse(Float64, ["105.2"]) ≈ 105.2
end