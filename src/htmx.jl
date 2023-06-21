struct hx
    node::Node    
end

const HTMX_ATTRS = [:trigger, :target, :post, :get, :put, :patch, :delete, :swap, :indicator, :sync, :preserve, :include, :params, :encoding, :confirm, :disinherit, :boost, :select, Symbol("push-url"), Symbol("select-oob"), Symbol("swap-oob"), Symbol("history-elt")]

#Base.propertynames(x::hx) = Symbol.(keys(x.node))
Base.propertynames(::hx) = HTMX_ATTRS
Base.propertynames(::Type{hx}) = HTMX_ATTRS
Base.getproperty(x::hx, name::Symbol) = name == :node ? getfield(x, :node) : attrs(x.node)["hx-$name"]
Base.getproperty(::Type{hx}, name::Symbol) = name in HTMX_ATTRS ? name : error("hx does not have property $name")
Base.setproperty!(x::hx, name::Symbol, v) = attrs(x.node)["hx-$name"] = string(v)

Base.get(x::hx, name, val) = get(attrs(x.node), string(name), string(val))
Base.get!(x::hx, name, val) = get!(attrs(x.node), string(name), string(val))
Base.haskey(x::hx, name) = haskey(attrs(x.node), string(name))
Base.keys(x::hx) = keys(attrs(x.node))

(x::hx)(name::Union{String,Symbol}, value::Union{String,Symbol}) = attrs(x.node)["hx-$name"] = "$value"
(x::hx)(p::Pair{Union{String,Symbol},Union{String,Symbol}}) = attrs(x.node)["hx-$(p[1])"] = "$(p[2])"

const SWAP_ATTRS = [:innerHTML, :outerHTML, :afterbegin, :afterend, :beforebegin, :beforeend]
swap() = (:swap => :innerHTML)
swap(name::Symbol) = name in SWAP_ATTRS ? (:swap => name) : error("swap does not have property $name")
Base.propertynames(::typeof(swap)) = SWAP_ATTRS
Base.getproperty(::typeof(swap), name::Symbol) = swap(name)




