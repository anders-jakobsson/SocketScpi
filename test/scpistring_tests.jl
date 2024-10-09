@testset "Construction" begin
	@test "scpi\"*IDN;*RST\"" == repr(ScpiString("*IDN", "*RST"))
	@test "scpi\"*IDN;*RST\"" == repr(scpi"*IDN"*"*RST")
	@test "scpi\"*IDN;*RST\"" == repr("*IDN"*scpi"*RST")
	@test_throws ErrorException ScpiString()
	@test_throws MethodError ScpiString(1)
end

@testset "Queries" begin
	@test hasquery(scpi"*IDN?")==true
	@test hasquery(scpi"*IDN")==false
	@test numqueries(scpi"*IDN")==0
	@test numqueries(scpi"*IDN?")==1
	@test numqueries(scpi"*IDN?"^4)==4
end
