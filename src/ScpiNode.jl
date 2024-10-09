
struct ScpiNode
	command::String
	parent::Union{Nothing,ScpiNode}
	children::Dict{String,ScpiNode}
	writable::Bool
	readable::Bool
end

function ScpiNode(abbreviated=false)
	# This is only used to generate the root node.
	root = ScpiNode("", nothing, Dict{String,ScpiNode}(), false, false)
	ScpiNode(root, "CLS", true, false)
	ScpiNode(root, "ESE", true, true)
	ScpiNode(root, "ESR", false, true)
	ScpiNode(root, "ESR", false, true)
	ScpiNode(root, "OPC", true, true)
	ScpiNode(root, "RST", true, false)
	ScpiNode(root, "SRE", true, true)
	ScpiNode(root, "STB", false, true)
	ScpiNode(root, "TST", false, true)
	ScpiNode(root, "WAI", true, false)
	system = ScpiNode(root, abbreviated ? "SYS" : "system", false, false)
	error = ScpiNode(system, abbreviated ? "ERR" : "error", false, true)
	ScpiNode(error, abbreviated ? "NEXT" : "next", false, true)
	ScpiNode(system, abbreviated ? "VERS" : "version", false, true)
	status = ScpiNode(root, abbreviated ? "STAT" : "status", false, false)
	operation = ScpiNode(status, abbreviated ? "OPER" : "operation", false, true)
	ScpiNode(operation, abbreviated ? "EVEN" : "event", false, true)
	ScpiNode(operation, abbreviated ? "COND" : "condition", false, true)
	ScpiNode(operation, abbreviated ? "ENAB" : "enable", true, true)
	questionable = ScpiNode(status, abbreviated ? "QUES" : "questionable", false, true)
	ScpiNode(questionable, abbreviated ? "EVEN" : "event", false, true)
	ScpiNode(questionable, abbreviated ? "COND" : "condition", false, true)
	ScpiNode(questionable, abbreviated ? "ENAB" : "enable", true, true)
	ScpiNode(status, abbreviated ? "PRES" : "preset", true, false)
	return root
end

function ScpiNode(parent::ScpiNode, name::AbstractString, writable=true, readable=true)
	if startswith(name,'*')
		cmd = name
	else
		cmd = getfield(parent,:command) * ":" * name
	end
	node = ScpiNode(cmd, parent, Dict{String,ScpiNode}(), writable, readable)
	getfield(parent,:children)[name] = node
	return node
end


function Base.show(io::IO, ::MIME"text/plain", n::ScpiNode)
	command = getfield(n,:command)
	str = ""
	children = getfield(n, :children)
	for key in keys(children)
		str *= ":"*key*"\n"
	end
	print(io, str[begin:end-1])
end

function Base.propertynames(n::ScpiNode, private::Bool=false)
	if private
		return fieldnames(ScpiNode)
	end
	ltfun = (a,b)->lowercase(a)<lowercase(b)
	children = getfield(n, :children)
	names = collect(keys(children))
	# names = replace.(names, '*'=>"")
	return Symbol.(sort(names, lt=ltfun))
end

function Base.getproperty(n::ScpiNode, sym::Symbol)
	if sym ∈ (:command, :parent, :children, :writable, :readable)
		return getfield(n, sym)
	end
	children = getfield(n, :children)
	children[string(sym)]
end



# struct ScpiEventCommand
# 	command::ScpiString
# end
# (node::ScpiEventCommand)(q::Symbol) = ScpiString(node.command._str*"?")

# struct _CommonSystemError end
# (node::_CommonSystemError)(q::Symbol) = scpi":system:error?"
# Base.show(io::IO, ::MIME"text/plain", x::_CommonSystemError) = print(io, ":system:error")

# _CommonSystem = (
# 	error = _CommonSystemError(),
# 	version = ScpiEventCommand(scpi":system:version")
# )


# struct _CommonStatusOperation
# 	condition::ScpiEventCommand
# 	enable::ScpiEventCommand
# 	_CommonStatusOperation() = new(ScpiEventCommand(scpi":system:status:operation:condition"), ScpiEventCommand(scpi":system:status:operation:enable"))
# end
# (node::_CommonStatusOperation)(q::Symbol) = scpi":status:operation?"
# Base.show(io::IO, ::MIME"text/plain", x::_CommonStatusOperation) = print(io, ":status:operation")

# struct _CommonStatusQuestionable
# 	condition::ScpiEventCommand
# 	enable::ScpiEventCommand
# 	_CommonStatusQuestionable() = new(ScpiEventCommand(scpi":system:status:questionable:condition"), ScpiEventCommand(scpi":system:status:questionable:enable"))
# end
# (node::_CommonStatusQuestionable)(q::Symbol) = scpi":status:questionable?"
# Base.show(io::IO, ::MIME"text/plain", x::_CommonStatusQuestionable) = print(io, ":status:questionable")


# _CommonStatus = (
# 	operation = _CommonStatusOperation(),
# 	questionable = _CommonStatusQuestionable(),
# 	preset = ScpiEventCommand(scpi":status:preset")
# )

# Common = (
# 	CLS = ScpiEventCommand(scpi"*CLS"),
# 	ESE = ScpiEventCommand(scpi"*ESE"),
# 	ESR = ScpiEventCommand(scpi"*ESR"),
# 	IDN = ScpiEventCommand(scpi"*IDN"),
# 	OPC = ScpiEventCommand(scpi"*OPC"),
# 	RST = ScpiEventCommand(scpi"*RST"),
# 	SRE = ScpiEventCommand(scpi"*SRE"),
# 	STB = ScpiEventCommand(scpi"*STB"),
# 	TST = ScpiEventCommand(scpi"*TST"),
# 	WAI = ScpiEventCommand(scpi"*WAI"),
# 	system = _CommonSystem,
# 	status = _CommonStatus
# )

