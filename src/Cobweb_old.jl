module Cobweb

using DefaultApplication: DefaultApplication
using OrderedCollections: OrderedDict
using StyledStrings: @styled_str
import AbstractTrees: printnode, print_tree, children

export help, h, @h, preview, webdocs, Style, Class, Attributes, Children, Element, Document, IFrame, iframe

#-----------------------------------------------------------------------------# init
function __init__()
    global DIR = mktempdir()
end

#-----------------------------------------------------------------------------# (un)escape
escape(x::AbstractString) = replace(x, ESCAPE_CHARS...)
unescape(x::AbstractString) = replace(x, reverse.(ESCAPE_CHARS)...)
escape!(x) = (children(x) .= escape.(children(x)); return x)
unescape!(x) = (children(x) .= unescape.(children(x)); return x)

#-----------------------------------------------------------------------------# consts
const ESCAPE_CHARS = ('&' => "&amp;", '"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;")
const VOID_ELEMENTS = (:area,:base,:br,:col,:embed,:hr,:img,:input,:link,:meta,:param,:source,:track,:wbr)
const NAMED_COLORS = (:transparent,:aliceblue,:antiquewhite,:aqua,:aquamarine,:azure,:beige,:bisque,:black,:blanchedalmond,:blue,:blueviolet,:brown,:burlywood,:cadetblue,:chartreuse,:chocolate,:coral,:cornflowerblue,:cornsilk,:crimson,:cyan,:darkblue,:darkcyan,:darkgoldenrod,:darkgray,:darkgreen,:darkgrey,:darkkhaki,:darkmagenta,:darkolivegreen,:darkorange,:darkorchid,:darkred,:darksalmon,:darkseagreen,:darkslateblue,:darkslategray,:darkslategrey,:darkturquoise,:darkviolet,:deeppink,:deepskyblue,:dimgray,:dimgrey,:dodgerblue,:firebrick,:floralwhite,:forestgreen,:fuchsia,:gainsboro,:ghostwhite,:gold,:goldenrod,:gray,:green,:greenyellow,:grey,:honeydew,:hotpink,:indianred,:indigo,:ivory,:khaki,:lavender,:lavenderblush,:lawngreen,:lemonchiffon,:lightblue,:lightcoral,:lightcyan,:lightgoldenrodyellow,:lightgray,:lightgreen,:lightgrey,:lightpink,:lightsalmon,:lightseagreen,:lightskyblue,:lightslategray,:lightslategrey,:lightsteelblue,:lightyellow,:lime,:limegreen,:linen,:magenta,:maroon,:mediumaquamarine,:mediumblue,:mediumorchid,:mediumpurple,:mediumseagreen,:mediumslateblue,:mediumspringgreen,:mediumturquoise,:mediumvioletred,:midnightblue,:mintcream,:mistyrose,:moccasin,:navajowhite,:navy,:oldlace,:olive,:olivedrab,:orange,:orangered,:orchid,:palegoldenrod,:palegreen,:paleturquoise,:palevioletred,:papayawhip,:peachpuff,:peru,:pink,:plum,:powderblue,:purple,:rebeccapurple,:red,:rosybrown,:royalblue,:saddlebrown,:salmon,:sandybrown,:seagreen,:seashell,:sienna,:silver,:skyblue,:slateblue,:slategray,:slategrey,:snow,:springgreen,:steelblue,:tan,:teal,:thistle,:tomato,:turquoise,:violet,:wheat,:white,:whitesmoke,:yellow,:yellowgreen)

include("generated.jl")  # ELEMENTS, GLOBAL_ATTRIBUTES, ATTRIBUTES, CSS_PROPERTIES

STYLE_PROPERTIES::Vector{Symbol} = []
CLASS_PROPERTIES::Vector{Symbol} = []

#-----------------------------------------------------------------------------# preview
function preview(x; reuse=true)
    file = reuse ? joinpath(DIR, "index.html") : string(tempname(), ".html")
    x2 = showable("text/html", x) ? x : HTML(x)
    Base.open(io -> show(io, MIME("text/html"), x2), touch(file), "w")
    DefaultApplication.open(file)
end

#-----------------------------------------------------------------------------# webdocs
webdocs(x::Symbol) = DefaultApplication.open("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/$x")
Base.getproperty(::typeof(webdocs), x::Symbol) = webdocs(x)
Base.propertynames(::typeof(webdocs)) = keys(ELEMENTS)

#-----------------------------------------------------------------------------# CSSUnits
module CSSUnits
    struct Unit{sym} end
    Base.:(*)(x::Number, u::Unit) = string(x, u)
    Base.show(io::IO, u::Unit{T}) where {T} = print(io, T)
    for unit in [:ch,:cm,:em,:ex,:fr,:in,:mm,:pc,:percent,:pt,:px,:rem,:vh,:vmax,:vmin,:vw]
        @eval export $unit
        @eval $unit = Unit{$(QuoteNode(unit))}()
    end
end

#-----------------------------------------------------------------------------# Style
struct Style <: AbstractDict{Symbol, String}
    dict::OrderedDict{Symbol, String}
end
dict(o::Style) = getfield(o, :dict)
Style(o::Style) = o
function Style(; kw...)
    o = Style(OrderedDict{Symbol, String}())
    for (k,v) in pairs(kw)
        o[k] = string(v)
    end
    return o
end
function Style(s::AbstractString)
    out = Style()
    for entry in split(s, ';')
        k, v = split(entry, ':')
        out[Symbol(strip(k))] = strip(v)
    end
    return out
end
function Base.show(io::IO, ::MIME"text/html", s::Style)
    print(io, '"')
    join(io, (string(k, ':', v) for (k,v) in getfield(s, :dict)), "; ")
    print(io, '"')
end
Base.length(o::Style) = length(dict(o))
Base.keys(o::Style) = keys(dict(o))
Base.values(o::Style) = values(dict(o))
Base.iterate(o::Style, state...) = iterate(dict(o), state...)
Base.getindex(o::Style, k::Symbol) = get(dict(o), k, nothing)
Base.getindex(o::Style, k::AbstractString) = getindex(o, Symbol(k))
function Base.setindex!(o::Style, v, k::Symbol)
    k in keys(CSS_PROPERTIES) || throw(ArgumentError(styled"{red: `$k`} is not a valid CSS property."))
    setindex!(dict(o), string(v), k)
end
Base.setindex!(o::Style, v, k::AbstractString) = setindex!(o, string(v), Symbol(k))
Base.copy(o::Style) = Style(copy(dict(o)))
Base.merge!(o::Style, x::Style...) = (merge!(dict(o), x...); o)
Base.merge(o::Style, x::Style...) = merge!(copy(o), x...)
Base.empty!(o::Style) = (empty!(dict(o)); o)
Base.empty(o::Style) = empty!(copy(o))
Base.sort!(o::Style; kw...) = (sort!(dict(o); kw...); o)
Base.sort(o::Style; kw...) = sort!(copy(o); kw...)

Base.propertynames(o::Style) = keys(CSS_PROPERTIES)
Base.getproperty(o::Style, k::Symbol) = getindex(o, k)
Base.setproperty!(o::Style, k::Symbol, v) = setindex!(o, v, k)



#-----------------------------------------------------------------------------# Class
struct Class <: AbstractVector{Symbol}
    names::Vector{Symbol}
end
Class(names::Union{Symbol, AbstractString}...) = Class(collect(Symbol.(names)))
Class(s::String) = Class(split(s, ' ')...)
Class(c::Class) = copy(c)

names(c::Class) = getfield(c, :names)
Base.iterate(c::Class, state...) = iterate(names(c), state...)
Base.getindex(c::Class, i::Integer) = names(c)[i]
Base.setindex!(c::Class, v, i::Integer) = names(c)[i] = v
Base.size(c::Class) = size(names(c))

Base.push!(c::Class, x) = (push!(names(c), Symbol(x)); c)
Base.pushfirst!(c::Class, x) = (pushfirst!(names(c), Symbol(x)); c)
Base.copy(c::Class) = Class(copy(names(c)))
Base.merge!(a::Class, b::Class) = (union!(append!(names(a), names(b))); a)
Base.merge(a::Class, b::Class) = merge!(copy(a), b)

# Base.getproperty(o::Class, k::String) = merge(o, Class(k))

function Base.show(io::IO, ::MIME"text/html", c::Class)
    print(io, '"')
    join(io, names(c), ' ')
    print(io, '"')
end
Base.string(c::Class) = join(names(c), ' ')

#-----------------------------------------------------------------------------# Attributes
struct Attributes <: AbstractDict{Symbol, String}
    style::Style
    class::Class
    others::OrderedDict{Symbol, String}
    function Attributes(style, class, others)
        for k in keys(others)
            k in keys(ATTRIBUTES) || k in GLOBAL_ATTRIBUTES || throw(ArgumentError(styled"{red: `$k`} is not a valid HTML attribute."))
        end
        new(style, class, others)
    end
end
Attributes(; style=Style(), class=Class(), kw...) = Attributes(Style(style), Class(class), OrderedDict{Symbol, String}(kw...))
style(o::Attributes) = getfield(o, :style)
class(o::Attributes) = getfield(o, :class)
others(o::Attributes) = getfield(o, :others)
Base.length(o::Attributes) = length(others(o)) + !isempty(style(o)) + !isempty(class(o))
function OrderedDict(o::Attributes)
    out = copy(others(o))
    isempty(style(o)) || (out[:style] = string(style(o)))
    isempty(class(o)) || (out[:class] = string(class(o)))
    return out
end
Base.iterate(o::Attributes, state...) = iterate(OrderedDict(o), state...)

Base.getindex(o::Attributes, k::Symbol) = k == :style ? style(o) : k == :class ? class(o) : get(others(o), k, nothing)
Base.getindex(o::Attributes, k::AbstractString) = getindex(o, Symbol(k))

function Base.setindex!(o::Attributes, v, k::Symbol)
    k in keys(ATTRIBUTES) || k in GLOBAL_ATTRIBUTES || throw(ArgumentError(styled"{red: `$k`} is not a valid HTML attribute."))
    k == :style ? setindex!(o, Style(v), k) :
    k == :class ? setindex!(o, Class(v), k) :
    setindex!(others(o), v, k)
end
Base.setindex!(o::Attributes, v, k::AbstractString) = setindex!(o, v, Symbol(k))

Base.propertynames(o::Attributes) = keys(ATTRIBUTES)
Base.getproperty(o::Attributes, k::Symbol) = getindex(o, k)
Base.setproperty!(o::Attributes, k::Symbol, v) = setindex!(o, v, k)

function Base.show(io::IO, ::MIME"text/html", o::Attributes)
    join(io, (v == true ? k : string(k, '=', '"', v, '"') for (k, v) in o), ' ')
end

Base.copy(o::Attributes) = Attributes(copy(style(o)), copy(class(o)), copy(others(o)))

function Base.merge!(a::Attributes, b::Attributes)
    merge!(style(a), style(b))
    merge!(class(a), class(b))
    merge!(others(a), others(b))
    return a
end
Base.merge(a::Attributes, b::AbstractDict) = merge!(copy(a), b)


#-----------------------------------------------------------------------------# Children
struct Children <: AbstractVector{Any}
    items::Vector{Any}
end
Children() = Children([])
Children(items...) = Children(collect(items))
items(c::Children) = getfield(c, :items)
Base.size(c::Children) = size(items(c))
Base.getindex(c::Children, i::Integer) = items(c)[i]
Base.setindex!(c::Children, v, i::Integer) = items(c)[i] = v
Base.push!(c::Children, x) = push!(items(c), x)
Base.pushfirst!(c::Children, x) = pushfirst!(items(c), x)
Base.deleteat!(c::Children, x) = deleteat!(items(c), x)
Base.copy(c::Children) = Children(copy(items(c)))

function Base.show(io::IO, ::MIME"text/html", c::Children)
    foreach(x -> showable("text/html", x) ? show(io, MIME("text/html"), x) : print(io, x), items(c))
end

#-----------------------------------------------------------------------------# Element
struct Element
    name::Symbol
    attributes::Attributes
    children::Children
    function Element(name::Symbol, attr::Attributes, children::Children)
        name in keys(ELEMENTS) || throw(ArgumentError(styled"{red:<$name>} is not a valid HTML element."))
        new(name, attr, children)
    end
end
Element(name::Symbol) = Element(name, Attributes(), Children())

function (o::Element)(x...; kw...)::Element
    append!(children(o), x)
    merge!(attrs(o), Attributes(; kw...))
    return o
end

# function help(o::Element)
#     out = []
#     append!(out, help(name(o)))
#     for (k, v) in pairs(attrs(o))
#         append!(out, help(k))
#     end
#     return out
# end

name(o::Element) = getfield(o, :name)
attrs(o::Element) = getfield(o, :attributes)
children(o::Element) = getfield(o, :children)

Base.copy(o::Element) = Element(name(o), copy(attrs(o)), copy(children(o)))

Base.propertynames(o::Element) = union(GLOBAL_ATTRIBUTES, ELEMENTS[name(o)].attributes)
Base.getproperty(o::Element, k::Symbol) = attrs(o)[k]
Base.setproperty!(o::Element, k::Symbol, v) = attrs(o)[k] = v
Base.setproperty!(o::Element, k::AbstractString, v) = attrs(o)[:class] = v

function Base.getproperty(o::Element, k::String)
    out = copy(o)
    push!(out.class, Symbol(k))
    return out
end

Base.getindex(o::Element, i::Integer) = children(o)[i]
Base.setindex!(o::Element, v, i::Integer) = children(o)[i] = v
Base.length(o::Element) = length(children(o))
Base.push!(o::Element, x) = push!(children(o), x)
Base.pushfirst!(o::Element, x) = pushfirst!(children(o), x)
Base.deleteat!(o::Element, x) = deleteat!(children(o), x)

function print_opening(io::IO, o::Element)
    print(io, '<', name(o), isempty(attrs(o)) ? "" : " ")
    show(io, MIME("text/html"), attrs(o))
    print(io, '>')
end
function printnode(io::IO, o::Element)
    s = sprint(print_opening, o)
    print(io, styled"{bright_cyan:$s}", styled" {gray:($(length(children(o))) children)}")
end
Base.show(io::IO, ::MIME"text/plain", o::Element) = print_tree(io, o)

function Base.show(io::IO, ::MIME"text/html", o::Element)
    print_opening(io, o)
    show(io, MIME("text/html"), children(o))
    name(o) in VOID_ELEMENTS || print(io, "</", name(o), '>')
end

#-----------------------------------------------------------------------------# h
h(tag, children...; kw...) = Element(tag, Attributes(; kw...), Children(children...))

Base.propertynames(::typeof(h)) = keys(ELEMENTS)
Base.getproperty(::typeof(h), tag::Symbol) = h(tag)

#-----------------------------------------------------------------------------# Document
struct Document
    children::Children
end
Document(children...) = Document(Children(children...))

function Base.show(io::IO, ::MIME"text/html", o::Document)
    println(io, "<!DOCTYPE html>")
    show(io, MIME("text/html"), o.children)
end

#-----------------------------------------------------------------------------# iframe
iframe(children...; kw...) = h.iframe(; kw..., srcdoc = escape(repr("text/html", Children(children...))))

"IFrame is deprecated.  See `Cobweb.iframe`."
function IFrame(x; kw...)
    Base.depwarn("IFrame", :iframe, force=true)
    iframe(x; kw...)
end

#-----------------------------------------------------------------------------# @h
"""
    @h ex

Convert any valid HTML `<tag>` in `ex` to `Cobweb.h.<tag>`.

### Examples

    @h div(p("This is a paragraph"), p("Here is some", strong("bold"), "text"))
    # <div><p>This is a paragraph</p><p>Here is some<strong>bold</strong>text</p></div>
"""
macro h(ex)
    esc(_h(ex))
end

_h(ex::Expr) = (ex.args .= _h.(ex.args); return ex)
_h(x::Symbol) = x in propertynames(h) ? Expr(:., :(Cobweb.h), QuoteNode(x)) : x
_h(x) = x



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

String wrapper to identify content as CSS.  Will be displayed appropriately in text/css and text/html mime types.
"""
struct CSS
    x::String
end
Base.show(io::IO, ::MIME"text/css", c::CSS) = print(io, c.x)
Base.show(io::IO, ::MIME"text/html", c::CSS) = print(io, "<style>", c.x, "</style>")

macro css_str(ex)
    esc(Cobweb.CSS(ex))
end

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


#-----------------------------------------------------------------------------# parser
include("parser.jl")

end #module
