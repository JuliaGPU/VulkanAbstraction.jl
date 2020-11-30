function fetch_aliases(xroot)
    alias_nodes = findall("//@alias", xroot)
    OrderedDict(
        Symbol(alias.parentelement["name"]) => Symbol(alias.parentelement["alias"]) for alias ∈ alias_nodes
    )
end

function build_alias_graph(alias_verts, aliases_dict)
    aliases_g = SimpleDiGraph(length(alias_verts))

    for (j, (src, dst)) ∈ enumerate(aliases_dict)
        i = findfirst(dst .== alias_verts)
        add_edge!(aliases_g, i, j)
    end
    aliases_g
end

const aliases_dict = fetch_aliases(xroot)
const aliases_dict_rev = OrderedDict(v => k for (k, v) ∈ aliases_dict)

"""
Whether this type is an alias for another name.
"""
isalias(name) = name ∈ keys(aliases_dict)

"""
Whether an alias was built from this name.
"""
hasalias(name) = name ∈ values(aliases_dict)

alias_verts = unique(vcat(keys(aliases_dict)..., values(aliases_dict)...))

aliases_g = build_alias_graph(alias_verts, aliases_dict)

aliases(aliases_g::SimpleDiGraph, index) = getindex.(Ref(alias_verts), outneighbors(aliases_g, index))
aliases(name) = (index = findfirst(alias_verts .== name); isnothing(index) ? String[] : aliases(aliases_g, index))

function follow_alias(aliases_g::SimpleDiGraph, index)
    indices = inneighbors(aliases_g, index)
    if isempty(indices)
        alias_verts[index]
    elseif length(indices) > 1
        error("More than one indices returned for $(alias_verts[index]) when following alias $(getindex.(Ref(alias_verts), indices))")
    else
        alias_verts[first(indices)]
    end
end

follow_alias(name) = (index = findfirst(alias_verts .== name); isnothing(index) ? name : follow_alias(aliases_g, index))

@assert follow_alias(:VkPhysicalDeviceMemoryProperties2KHR) == :VkPhysicalDeviceMemoryProperties2
@assert follow_alias(:VkPhysicalDeviceMemoryProperties2) == :VkPhysicalDeviceMemoryProperties2
