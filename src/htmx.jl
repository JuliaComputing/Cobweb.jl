struct hx
    node::Node    
end

const HTMX_ATTRS = [:trigger, :target, :post, :get, :put, :patch, :delete, :swap, :indicator, :sync, :preserve, :include, :params, :encoding, :confirm, :disinherit, :boost, :select, :pushurl, :selectoob, :swapoob, :historyelt]
const HIPHENATED = Dict(:pushurl => Symbol("push-url"), :selectoob => Symbol("select-oob"), :swapoob => Symbol("swap-oob"), :historyelt => Symbol("history-elt"))

getattr(x::Symbol) = haskey(HIPHENATED, x) ? HIPHENATED[x] : x

Base.propertynames(::hx) = HTMX_ATTRS
Base.propertynames(::Type{hx}) = HTMX_ATTRS
Base.getproperty(x::hx, name::Symbol) = name == :node ? getfield(x, :node) : attrs(x.node)["hx-$(getattr(name))"]
Base.getproperty(::Type{hx}, name::Symbol) = name in HTMX_ATTRS ? getattr(name) : error("hx does not have property $name")
Base.setproperty!(x::hx, name::Symbol, v) = attrs(x.node)["hx-$(getattr(name))"] = string(v)

Base.get(x::hx, name, val) = get(attrs(x.node), string(getattr(name)), string(val))
Base.get!(x::hx, name, val) = get!(attrs(x.node), string(getattr(name)), string(val))
Base.haskey(x::hx, name) = haskey(attrs(x.node), string(getattr(name)))
Base.keys(x::hx) = keys(attrs(x.node))

(x::hx)(name::Symbol, value::Union{String,Symbol}) = attrs(x.node)["hx-$(getattr(name))"] = "$value"
(x::hx)(name::String, value::Union{String,Symbol}) = x(Symbol(name), value)
(x::hx)(p::Pair{Symbol,<:Union{String,Symbol}}) = attrs(x.node)["hx-$(getattr(p[1]))"] = "$(p[2])"
(x::hx)(p::Pair{String,<:Union{String,Symbol}}) = x(Symbol(p[1]), p[2])

# swap related stuff
const SWAP_ATTRS = [:innerHTML, :outerHTML, :afterbegin, :afterend, :beforebegin, :beforeend]
swap() = (:swap => :innerHTML) # the default - don't expect this to be used
swap(name::Symbol) = name in SWAP_ATTRS ? (:swap => name) : error("swap does not have property $name")
Base.propertynames(::typeof(swap)) = SWAP_ATTRS
Base.getproperty(::typeof(swap), name::Symbol) = name in SWAP_ATTRS ? name : error("swap does not have property $name")




