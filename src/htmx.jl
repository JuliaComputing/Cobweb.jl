_htmxcdn = h.script(; src="https://unpkg.com/htmx.org@1.9.2", integrity="sha384-L6OqL9pRWyyFU3+/bjdSri+iIphTN/bvYyM37tICVyOJkWZLpP2vGn6VUEXgzg6h", crossorigin="anonymous")

struct hx
    node::Node    
end

_node(o::hx) = getfield(o, :node)
tag(o::hx) = getfield(o |> _node, :tag)
attrs(o::hx) = getfield(o |> _node, :attrs)
children(o::hx) = getfield(o |> _node, :children)

const HTMX_ATTRS = [:trigger, :target, :post, :get, :put, :patch, :delete, :swap, :indicator, :sync, :preserve, :include, :params, :encoding, :confirm, :disinherit, :boost, :select, :pushurl, :selectoob, :swapoob, :historyelt]
const HIPHENATED = Dict(:pushurl => Symbol("push-url"), :selectoob => Symbol("select-oob"), :swapoob => Symbol("swap-oob"), :historyelt => Symbol("history-elt"))

getattr(x::Symbol) = haskey(HIPHENATED, x) ? HIPHENATED[x] : x

Base.propertynames(::hx) = HTMX_ATTRS
Base.propertynames(::Type{hx}) = HTMX_ATTRS
Base.getproperty(x::hx, name::Symbol) = name == :node ? _node(x) : attrs(x)["hx-$(getattr(name))"]
function Base.getproperty(::Type{hx}, name::Symbol) 
    if name == :cdn
        _htmxcdn
    elseif name in HTMX_ATTRS
        getattr(name)
    else 
        error("hx does not have property $name")
    end
end
Base.setproperty!(x::hx, name::Symbol, v) = attrs(x.node)["hx-$(getattr(name))"] = string(v)

Base.get(x::hx, name, val) = get(attrs(x.node), string(getattr(name)), string(val))
Base.get!(x::hx, name, val) = get!(attrs(x.node), string(getattr(name)), string(val))
Base.haskey(x::hx, name) = haskey(attrs(x.node), string(getattr(name)))
Base.keys(x::hx) = keys(attrs(x.node))

function (x::hx)(; kw...)
    hxattrs = OrderedDict("hx-$(getattr(Symbol(k)))" => string(v) for (k,v) in kw) 
    Node(tag(x), merge(attrs(x), hxattrs), children(x))
end

# swap related stuff
const SWAP_ATTRS = [:innerHTML, :outerHTML, :afterbegin, :afterend, :beforebegin, :beforeend]
swap() = (:swap => :innerHTML) # the default - don't expect this to be used
swap(name::Symbol) = name in SWAP_ATTRS ? (:swap => name) : error("swap does not have property $name")
Base.propertynames(::typeof(swap)) = SWAP_ATTRS
Base.getproperty(::typeof(swap), name::Symbol) = name in SWAP_ATTRS ? name : error("swap does not have property $name")






