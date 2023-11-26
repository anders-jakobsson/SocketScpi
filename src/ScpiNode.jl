

struct ScpiNode
	command::String
	parent::Union{Nothing,ScpiNode}
	children::Dict{String,ScpiNode}
	writable::Bool
	readable::Bool
end

function ScpiNode()
	ScpiNode("", nothing, Dict{String,ScpiNode}(), false, false)
end

function ScpiNode(parent::ScpiNode, name::AbstractString, writable=true, readable=true)
	if startswith(name,'*')
		cmd = name
	else
		cmd = parent.command * ":" * name
	end
	node = ScpiNode(cmd, parent, Dict{String,ScpiNode}(), writable, readable)
	parent.children[name] = node
	return node
end


function Base.show(io::IO, n::ScpiNode)
	println(io, n.command)
	for key in keys(n.children)
		println(io, n.children[key].command)
	end
end

function Base.propertynames(n::ScpiNode, private::Bool=false)
	if private
		return fieldnames(ScpiNode)
	end
	ltfun = (a,b)->lowercase(a)<lowercase(b)
	names = collect(keys(n.children))
	names = replace.(names, '*'=>"")
	return Symbol.(sort(names, lt=ltfun))
end



struct ScpiEventCommand
	command::ScpiString
end
(node::ScpiEventCommand)(q::Symbol) = ScpiString(node.command._str*"?")

struct _CommonSystemError end
(node::_CommonSystemError)(q::Symbol) = scpi":system:error?"
Base.show(io::IO, ::MIME"text/plain", x::_CommonSystemError) = print(io, ":system:error")

_CommonSystem = (
	error = _CommonSystemError(),
	version = ScpiEventCommand(scpi":system:version")
)


struct _CommonStatusOperation
	condition::ScpiEventCommand
	enable::ScpiEventCommand
	_CommonStatusOperation() = new(ScpiEventCommand(scpi":system:status:operation:condition"), ScpiEventCommand(scpi":system:status:operation:enable"))
end
(node::_CommonStatusOperation)(q::Symbol) = scpi":status:operation?"
Base.show(io::IO, ::MIME"text/plain", x::_CommonStatusOperation) = print(io, ":status:operation")

struct _CommonStatusQuestionable
	condition::ScpiEventCommand
	enable::ScpiEventCommand
	_CommonStatusQuestionable() = new(ScpiEventCommand(scpi":system:status:questionable:condition"), ScpiEventCommand(scpi":system:status:questionable:enable"))
end
(node::_CommonStatusQuestionable)(q::Symbol) = scpi":status:questionable?"
Base.show(io::IO, ::MIME"text/plain", x::_CommonStatusQuestionable) = print(io, ":status:questionable")


_CommonStatus = (
	operation = _CommonStatusOperation(),
	questionable = _CommonStatusQuestionable(),
	preset = ScpiEventCommand(scpi":status:preset")
)

Common = (
	CLS = ScpiEventCommand(scpi"*CLS"),
	ESE = ScpiEventCommand(scpi"*ESE"),
	ESR = ScpiEventCommand(scpi"*ESR"),
	IDN = ScpiEventCommand(scpi"*IDN"),
	OPC = ScpiEventCommand(scpi"*OPC"),
	RST = ScpiEventCommand(scpi"*RST"),
	SRE = ScpiEventCommand(scpi"*SRE"),
	STB = ScpiEventCommand(scpi"*STB"),
	TST = ScpiEventCommand(scpi"*TST"),
	WAI = ScpiEventCommand(scpi"*WAI"),
	system = _CommonSystem,
	status = _CommonStatus
)

