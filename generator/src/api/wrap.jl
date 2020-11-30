mutable struct WrappedAPI
    source
    structs::OrderedDict{String, SDefinition}
    funcs::OrderedDict{String, FDefinition}
    consts::OrderedDict{String, CDefinition}
    enums::OrderedDict{String, EDefinition}
    misc
    bags
    extended_vk_constructors
end

vars(w_api) = OrderedDict([k => v for field ∈ getproperty.(Ref(w_api), [:structs, :funcs, :consts, :enums]) for (k, v) ∈ field])

Base.show(io::IO, w_api::WrappedAPI) = print(io, "Wrapped API with $(length(w_api.structs)) structs, $(length(w_api.funcs)) functions, $(length(w_api.consts)) consts and $(length(w_api.enums)) enums wrapped from $(w_api.source)")

name_transform(decl::Declaration) = name_transform(decl.name, typeof(decl))

function wrap(library_api::API)
    global api = library_api
    w_api = WrappedAPI(api.source, OrderedDict{String, SDefinition}(), OrderedDict{String, FDefinition}(), OrderedDict{String, CDefinition}(), OrderedDict{String, EDefinition}(), String[], OrderedDict{String, SDefinition}(), OrderedDict{String, FDefinition}())
    wrap!(w_api)
end

function wrap!(w_api::WrappedAPI)
    errors = OrderedDict()
    wrap!(w_api, values(api.structs))
    wrap!(w_api, values(api.funcs))
    wrap!(w_api, values(api.consts))
    wrap!(w_api, values(api.enums))
    @info("API successfully wrapped.")
    w_api
end

function wrap!(w_api, objects)
    foreach(objects) do obj
        try
            wrap!(w_api, obj)
        catch e
            msg = hasproperty(e, :msg) ? e.msg : "$(typeof(e))"
            println("\e[31;1;1m$(name(obj)): $msg\e[m")
            rethrow(e)
        end
    end
end

function wrap!(w_api, sdef::SDefinition)
    new_sdef = structure(sdef)
    has_bag(sdef.name) && setindex!(w_api.bags, create_bag(sdef), bagtype(sdef.name))
    wrap_structure!(w_api, new_sdef)
    wrap_constructor!(w_api, new_sdef, sdef)
end

function wrap!(w_api, fdef::FDefinition)
    if is_command_type(fdef.name, ENUMERATE)
        new_fdef = wrap_enumeration_command(typed_fdef(fdef))
    elseif startswith(fdef.name, "vkDestroy")
        return
    elseif !is_command_type(fdef.name, CREATE)
        new_fdef = wrap_generic(typed_fdef(fdef))
    else
        return
    end
    w_api.funcs[new_fdef.name] = new_fdef
end

function wrap!(w_api, edef::EDefinition)
    new_edef = EDefinition(remove_vk_prefix(edef.ex))
    old = name(edef)
    new = name(new_edef)
    w_api.enums[new] = new_edef
    w_api.funcs["convert_$old"] = FDefinition("Base.convert(T::Type{$new}, e::$old) = T(UInt(e))")
    w_api.funcs["convert_$new"] = FDefinition("Base.convert(T::Type{$old}, e::$new) = T(UInt(e))")
end

function wrap!(w_api, cdef::CDefinition)
    if !is_handle(name(cdef))
        new_cdef = CDefinition(remove_vk_prefix(cdef.ex))
        w_api.consts[name(new_cdef)] = new_cdef
    end
end

include("wrapping/struct_logic.jl")
include("wrapping/constructor_logic.jl")
include("wrapping/function_logic.jl")