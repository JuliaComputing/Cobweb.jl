struct hx
    node::Node    
end

const HTMX_ATTRS = [:trigger, :target, :post, :get, :put, :patch, :delete, :swap, :indicator, :sync, Symbol("swap-oob")]

Base.propertynames(x::hx) = Symbol.(keys(x.node))
Base.propertynames(::hx) = HTMX_ATTRS
Base.propertynames(::Type{hx}) = HTMX_ATTRS
Base.getproperty(x::hx, name::Symbol) = name == :node ? getfield(x, :node) : attrs(x.node)["hx-$name"]
Base.setproperty!(x::hx, name::Symbol, v) = attrs(x.node)["hx-$name"] = string(v)

Base.get(x::hx, name, val) = get(attrs(x.node), string(name), string(val))
Base.get!(x::hx, name, val) = get!(attrs(x.node), string(name), string(val))
Base.haskey(x::hx, name) = haskey(attrs(x.node), string(name))
Base.keys(x::hx) = keys(attrs(x.node))

