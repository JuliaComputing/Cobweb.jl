module Cobweb

using DefaultApplication: DefaultApplication
using Scratch: @get_scratch!
using OrderedCollections: OrderedDict

export Page, Tab, h, preview, IFrame, @js_str, @css_str

#-----------------------------------------------------------------------------# init
function __init__()
    global DIR = @get_scratch!("CobWeb")
end

#-----------------------------------------------------------------------------# preview
function preview(content; reuse=true)
    file = reuse ? joinpath(DIR, "index.html") : string(tempname(), ".html")
    content2 = showable("text/html", content) ? content : HTML(content)
    Base.open(io -> show(io, MIME("text/html"), content2), touch(file), "w")
    DefaultApplication.open(file)
end

#-----------------------------------------------------------------------------# Page
function Page(x)
    Base.depwarn("Page(x) is deprecated.  Use preview(x) instead.", :Page; force=true)
    preview(x)
end
function Tab(x)
    Base.depwarn("Tab(x) is deprecated.  Use preview(x; reuse=false) instead.", :Tab; force=true)
    preview(x; reuse=false)
end

#-----------------------------------------------------------------------------# consts
const HTML5_TAGS = [:a,:abbr,:address,:area,:article,:aside,:audio,:b,:base,:bdi,:bdo,:blockquote,:body,:br,:button,:canvas,:caption,:cite,:code,:col,:colgroup,:command,:datalist,:dd,:del,:details,:dfn,:dialog,:div,:dl,:dt,:em,:embed,:fieldset,:figcaption,:figure,:footer,:form,:h1,:h2,:h3,:h4,:h5,:h6,:head,:header,:hgroup,:hr,:html,:i,:iframe,:img,:input,:ins,:kbd,:label,:legend,:li,:link,:main,:map,:mark,:math,:menu,:menuitem,:meta,:meter,:nav,:noscript,:object,:ol,:optgroup,:option,:output,:p,:param,:picture,:pre,:progress,:q,:rb,:rp,:rt,:rtc,:ruby,:s,:samp,:script,:section,:select,:slot,:small,:source,:span,:strong,:style,:sub,:summary,:sup,:svg,:table,:tbody,:td,:template,:textarea,:tfoot,:th,:thead,:time,:title,:tr,:track,:u,:ul,:var,:video,:wbr]

const VOID_ELEMENTS = [:area,:base,:br,:col,:command,:embed,:hr,:img,:input,:keygen,:link,:meta,:param,:source,:track,:wbr]

const SVG2_TAGS = [:a,:animate,:animateMotion,:animateTransform,:audio,:canvas,:circle,:clipPath,:defs,:desc,:discard,:ellipse,:feBlend,:feColorMatrix,:feComponentTransfer,:feComposite,:feConvolveMatrix,:feDiffuseLighting,:feDisplacementMap,:feDistantLight,:feDropShadow,:feFlood,:feFuncA,:feFuncB,:feFuncG,:feFuncR,:feGaussianBlur,:feImage,:feMerge,:feMergeNode,:feMorphology,:feOffset,:fePointLight,:feSpecularLighting,:feSpotLight,:feTile,:feTurbulence,:filter,:foreignObject,:g,:iframe,:image,:line,:linearGradient,:marker,:mask,:metadata,:mpath,:path,:pattern,:polygon,:polyline,:radialGradient,:rect,:script,:set,:stop,:style,:svg,:switch,:symbol,:text,:textPath,:title,:tspan,:unknown,:use,:video,:view]

const CSS_UNITS = [:ch,:cm,:em,:ex,:fr,:in,:mm,:pc,:percent,:pt,:px,:rem,:vh,:vmax,:vmin,:vw]

#-----------------------------------------------------------------------------# Node
"""
    Node(tag::Symbol, attrs::OrderedDict{Symbol,String}, children::Vector)

Should not often be used directly.  See `?Cobweb.h`.
"""
struct Node
    tag::Symbol
    attrs::OrderedDict{Symbol, String}
    children::Vector{Any}
end
function Node(tag::Symbol, attrs::OrderedDict{Symbol, String}, children::AbstractVector)
    tag in HTML5_TAGS || @warn "<$tag> is not a valid HTML5 tag."
    Node(tag, attrs, collect(children))
end
tag(o::Node) = getfield(o, :tag)
attrs(o::Node) = getfield(o, :attrs)
children(o::Node) = getfield(o, :children)

attrs(kw::AbstractDict) = OrderedDict(Symbol(k) => string(v) for (k,v) in pairs(kw))

(o::Node)(x...; kw...) = Node(tag(o), merge(attrs(o), attrs(kw)), vcat(children(o), x...))

Base.:(==)(a::Node, b::Node) = all(f(a) == f(b) for f in (tag, attrs, children))

# append classes
Base.getproperty(o::Node, class::String) = o(class = lstrip(get(o, :class, "") * " " * class))

# methods that pass through to attrs(o)
Base.propertynames(o::Node) = Symbol.(keys(o))
Base.getproperty(o::Node, name::Symbol) = attrs(o)[name]
Base.setproperty!(o::Node, name::Symbol, x) = attrs(o)[name] = string(x)
Base.get(o::Node, name, val) = get(attrs(o), string(name), string(val))
Base.get!(o::Node, name, val) = get!(attrs(o), string(name), string(val))
Base.haskey(o::Node, name) = haskey(attrs(o), string(name))
Base.keys(o::Node) = keys(attrs(o))

# methods that pass through to children(o)
Base.lastindex(o::Node) = lastindex(children(o))
Base.getindex(o::Node, i::Union{Integer, AbstractVector{<:Integer}, Colon}) = children(o)[i]
Base.setindex!(o::Node, x, i::Union{Integer, AbstractVector{<:Integer}, Colon}) = setindex!(children(o), x, i)
Base.length(o::Node) = length(children(o))
Base.iterate(o::Node) = iterate(children(o))
Base.iterate(o::Node, state) = iterate(children(o), state)
Base.push!(o::Node, x) = push!(children(o), x)
Base.append!(o::Node, x) = append!(children(o), x)

#-----------------------------------------------------------------------------# show Node
function print_opening_tag(io::IO, o::Node; self_close::Bool = false)
    print(io, '<', tag(o))
    for (k,v) in attrs(o)
        v == "true" ? print(io, ' ', k) : v != "false" && print(io, ' ', k, '=', '"', v, '"')
    end
    self_close && Symbol(tag(o)) ∉ VOID_ELEMENTS && length(children(o)) == 0 ?
        print(io, " />") :
        print(io, '>')
end

function Base.show(io::IO, o::Node)
    p(args...) = print(io, args...)
    print_opening_tag(io, o)
    foreach(x -> showable("text/html", x) ? show(io, MIME("text/html"), x) : p(x), children(o))
    tag(o) in VOID_ELEMENTS || p("</", tag(o), '>')
end

Base.show(io::IO, ::MIME"text/html", node::Node) = show(io, node)
Base.show(io::IO, ::MIME"text/xml", node::Node) = show(io, node)
Base.show(io::IO, ::MIME"application/xml", node::Node) = show(io, node)

Base.write(io::IO, node::Node) = show(io, MIME"text/html"(), node)

function pretty(io::IO, o::Node; depth=get(io, :depth, 0), indent=get(io, :indent, "    "), self_close = get(io, :self_close, true))
    p(args...) = print(io, args...)
    p(indent ^ depth)
    print_opening_tag(io, o; self_close)
    if length(children(o)) == 1 && !(only(o) isa Node)
        x = only(o)
        txt = showable("text/html", x) ? repr("text/html", x) : string(x)
        if occursin('\n', txt)
            println(io)
            foreach(line -> p(indent ^ (depth+1), line, '\n'), lstrip.(split(txt, '\n')))
            p(indent ^ depth, "</", tag(o), '>')
        else
            p(txt)
            p("</", tag(o), '>')
        end
    elseif length(children(o)) > 1
        child_io = IOContext(io, :depth => depth + 1, :indent => indent)
        for child in children(o)
            println(io)
            pretty(child_io, child)
        end
        p('\n', indent ^ depth, "</", tag(o), '>')
    end
end
function pretty(io::IO, x; depth=get(io, :depth, 0), indent=get(io, :indent, "  "))
    print(io, indent ^ depth)
    showable("text/html", x) ? show(io, MIME("text/html"), x) : print(io, x)
end
pretty(x; kw...) = (io = IOBuffer(); pretty(io, x; kw...); String(take!(io)))

#-----------------------------------------------------------------------------# h
"""
    h(tag, children...; kw...)
    h.tag(children...; kw...)

Create an html node with the given `tag`, `children`, and `kw` attributes.

### Examples

    h.div("child", class="myclass", id="myid")
    # <div class="myclass" id="myid">child</div>

    h.div."myclass"("content")
    # <div class="myclass">content</div>
"""
h(tag, children...; kw...) = Node(tag, attrs(kw), collect(children))

h(tag, attrs::AbstractDict, children...) = Node(tag, attrs, collect(children))

Base.getproperty(::typeof(h), tag::Symbol) = h(tag)

Base.propertynames(::typeof(h)) = HTML5_TAGS

#-----------------------------------------------------------------------------# @h
macro h(ex)
    esc(_h(ex))
end

function _h(ex::Expr)
    for (i, x) in enumerate(ex.args)
        ex.args[i] = x isa Expr ? _h(x) :
            x isa Symbol && x in HTML5_TAGS ? Expr(:., :(Cobweb.h), QuoteNode(x)) :
            x
    end
    ex
end
_h(x::Symbol) = x in propertynames(typeof(h)) ? Expr(:., :(Cobweb.h), QuoteNode(x)) : x

#-----------------------------------------------------------------------------# escape
escape_chars = ['&' => "&amp;", '"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;"]

function escape(x::AbstractString; patterns = escape_chars)
    for pat in patterns
        x = replace(x, pat)
    end
    return x
end

unescape(x::AbstractString) = escape(x; patterns = reverse.(escape_chars))


#-----------------------------------------------------------------------------# Javascript
"""
    Javascript(content::String)

String wrapper to identify content as Javascript.  Will be displayed appropriately in text/javascript and text/html mime types.
"""
struct Javascript
    x::String
end
Base.show(io::IO, ::MIME"text/javascript", j::Javascript) = print(io, j.x)
Base.show(io::IO, ::MIME"text/html", j::Javascript) = print(io, "<script>", j.x, "</script>")

macro js_str(ex)
    esc(Cobweb.Javascript(ex))
end

#-----------------------------------------------------------------------------# CSS
"""
    CSS(content::String)

Wrapper to identify content as CSS.  Will be displayed appropriately in text/css and text/html mime types.
"""
struct CSS
    x::String
end
Base.show(io::IO, ::MIME"text/css", c::CSS) = print(io, c.x)
Base.show(io::IO, ::MIME"text/html", c::CSS) = print(io, "<style>", c.x, "</style>")

macro css_str(ex)
    esc(Cobweb.CSS(ex))
end

#-----------------------------------------------------------------------------# Doctype
struct Doctype end
Base.show(io::IO, o::Doctype) = print(io, "<!DOCTYPE html>")
Base.show(io::IO, ::MIME"text/html", o::Doctype) = print(io, "<!DOCTYPE html>")

#-----------------------------------------------------------------------------# Comment
"""
    Comment(x)

Inserts into HTML as `<!-- \$(string(x)) ->`.
"""
struct Comment
    x::String
    Comment(x) = new(string(x))
end
Base.show(io::IO, ::MIME"text/html", o::Comment) = print(io, "<!-- ", o.x, " -->")

#-----------------------------------------------------------------------------# IFrame
"""
    IFrame(content; attrs...)

Create an `<iframe srcdoc=\$content \$(attrs...)>`.
"""
struct IFrame{T, KW}
    content::T
    kw::KW
    IFrame(x::T; kw...) where {T} = new{T, typeof(kw)}(x, kw)
end
function Base.show(io::IO, ::MIME"text/html", o::IFrame)
    show(io, h.iframe(; srcdoc=escape(repr("text/html", o.content)), o.kw...))
end

include("parser.jl")

end #module
