

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

