module Cobweb

using DefaultApplication: DefaultApplication
using Scratch: @get_scratch!
using OrderedCollections: LittleDict
using StyledStrings: @styled_str
import AbstractTrees: printnode, print_tree, children

export help, h, @h, preview, Style, Class, Attributes, Children, Element, Document, IFrame, iframe

#-----------------------------------------------------------------------------# init
function __init__()
    global DIR = @get_scratch!("CobWeb")
end

#-----------------------------------------------------------------------------# utils
const VOID_ELEMENTS = (:area,:base,:br,:col,:command,:embed,:hr,:img,:input,:keygen,:link,:meta,:param,:source,:track,:wbr)

escape_chars = ('&' => "&amp;", '"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;")

escape(x::AbstractString) = replace(x, escape_chars...)
unescape(x::AbstractString) = replace(x, reverse.(escape_chars)...)

#-----------------------------------------------------------------------------# preview
function preview(x; reuse=true)
    file = reuse ? joinpath(DIR, "index.html") : string(tempname(), ".html")
    x2 = showable("text/html", x) ? x : HTML(x)
    Base.open(io -> show(io, MIME("text/html"), x2), touch(file), "w")
    DefaultApplication.open(file)
end

#-----------------------------------------------------------------------------# generated.jl
struct AttributeSpec
    name::Symbol
    is_deprecated::Bool
    is_experimental::Bool
    is_global::Bool
    description::String
    elements::Vector{Symbol}
end
function Base.show(io::IO, o::AttributeSpec)
    print(io, styled"AttributeSpec: {bright_green:<$(o.name)>}")
    o.is_deprecated && print(io, styled" {bright_red:(deprecated)}")
    o.is_experimental && print(io, styled" {bright_yellow:(experimental)}")
    print(io, styled"\n    {gray:description: $(o.description)}")
end

struct ElementSpec
    name::Symbol
    is_deprecated::Bool
    is_experimental::Bool
    description::String
    attributes::Vector{Symbol}
end
function Base.show(io::IO, o::ElementSpec)
    print(io, styled"ElementSpec: {bright_green:<$(o.name)>}")
    o.is_deprecated && print(io, styled" {bright_red:(deprecated)}")
    o.is_experimental && print(io, styled" {bright_yellow:(experimental)}")
    print(io, styled"\n    {gray:description: $(o.description)}")
    isempty(o.attributes) || print(io, styled"\n    {bright_cyan:attributes:  $(o.attributes)}")
end

include("generated.jl")

#-----------------------------------------------------------------------------# help
function help(x::Symbol)
    out = []
    haskey(ELEMENTS, x) && push!(out, ELEMENTS[x])
    haskey(ATTRIBUTES, x) && push!(out, ATTRIBUTES[x])
    return out
end
Base.getproperty(::typeof(help), x::Symbol) = help(x)
Base.propertynames(::typeof(help)) = union(keys(ELEMENTS), keys(ATTRIBUTES))

#-----------------------------------------------------------------------------# Options
@kwdef struct Options
    style_autocomplete::Vector{Symbol} = [:height, :width, :border]
    style_validate::Bool = true
    class_autocomplete::Vector{Symbol} = []
    class_validate::Bool = false
    attribute_autcomplete::Vector{Symbol} = [:class, :style, :id]
    attribute_validate::Bool = true
    element_autocomplete::Vector{Symbol} = sort!(collect(keys(ELEMENTS)))
    element_validate::Bool = true
end
function Base.show(io::IO, ::MIME"text/plain", o::Options)
    print(io, "Options --> ")
    show(io, MIME"text/plain"(), Dict(k => getfield(o,k) for k in fieldnames(Options)))
end

options::Options = Options()

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
    dict::LittleDict{Symbol, String}
end
function Style(; kw...)
    o = Style(LittleDict{Symbol, String}())
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
(s::Style)(; kw...) = merge(s, Style(; kw...))
Style(s::Style) = copy(s)
Base.length(s::Style) = length(getfield(s, :dict))
Base.iterate(s::Style, state...) = iterate(getfield(s, :dict), state...)
Base.getindex(s::Style, k::Symbol) = get(getfield(s, :dict), k, nothing)
function Base.setindex!(s::Style, v, k::Symbol)
    options.style_validate && k in CSS_PROPERTIES || throw(ArgumentError(styled"{red:\"$k\"} is not a valid CSS property."))
    getfield(s, :dict)[k] = string(v)
end
Base.propertynames(s::Style) = options.style_autocomplete
Base.getproperty(s::Style, k::Symbol) = getindex(s, k)
Base.setproperty!(s::Style, k::Symbol, v) = setindex!(s, v, k)
Base.isempty(s::Style) = isempty(getfield(s, :dict))

function Base.merge!(a::Style, b::AbstractDict)
    for (k,v) in pairs(b)
        a[k] = v
    end
    return a
end
Base.merge(a::Style, b::AbstractDict) = merge!(copy(a), b)
Base.copy(s::Style) = Style(copy(getfield(s, :dict)))

function Base.show(io::IO, ::MIME"text/html", s::Style)
    print(io, '"')
    join(io, (string(k, ':', v) for (k,v) in getfield(s, :dict)), "; ")
    print(io, '"')
end
Base.string(s::Style) = join((string(k, ':', v) for (k,v) in getfield(s, :dict)), "; ")

LittleDict(s::Style) = LittleDict(:style => string(s))

#-----------------------------------------------------------------------------# Class
struct Class <: AbstractVector{Symbol}
    names::Vector{Symbol}
end
Class(names::Union{Symbol, AbstractString}...) = Class(collect(Symbol.(names)))
Class(s::String) = Class(split(s, ' ')...)
Class(c::Class) = copy(c)
names(c::Class) = getfield(c, :names)
Base.length(c::Class) = length(names(c))
Base.iterate(c::Class, state...) = iterate(names(c), state...)
Base.getindex(c::Class, i::Integer) = names(c)[i]
Base.setindex!(c::Class, v, i::Integer) = names(c)[i] = v
Base.size(c::Class) = size(names(c))
Base.push!(c::Class, x) = push!(names(c), Symbol(x))
Base.pushfirst!(c::Class, x) = pushfirst!(names(c), Symbol(x))
Base.isempty(o::Class) = isempty(names(o))
Base.copy(c::Class) = Class(copy(names(c)))
Base.merge!(a::Class, b::Class) = (append!(names(a), names(b)); a)
Base.merge(a::Class, b::Class) = merge!(copy(a), b)

Base.getproperty(o::Class, k::String) = merge(o, Class(k))

function Base.show(io::IO, ::MIME"text/html", c::Class)
    print(io, '"')
    join(io, names(c), ' ')
    print(io, '"')
end
Base.string(c::Class) = join(names(c), ' ')

LittleDict(c::Class) = LittleDict(:class => string(c))

#-----------------------------------------------------------------------------# Attributes
struct Attributes <: AbstractDict{Symbol, String}
    style::Style
    class::Class
    others::LittleDict{Symbol, String}
    function Attributes(style, class, others)
        options.attribute_validate && for k in keys(others)
            k in keys(ATTRIBUTES) || throw(ArgumentError(styled"{red: `$k`} is not a valid HTML attribute."))
        end
        new(style, class, others)
    end
end
Attributes(; style=Style(), class=Class(), kw...) = Attributes(Style(style), Class(class), LittleDict{Symbol, String}(kw...))
style(o::Attributes) = getfield(o, :style)
class(o::Attributes) = getfield(o, :class)
others(o::Attributes) = getfield(o, :others)
Base.length(o::Attributes) = length(others(o)) + !isempty(style(o)) + !isempty(class(o))
function LittleDict(o::Attributes)
    out = copy(others(o))
    isempty(style(o)) || (out[:style] = string(style(o)))
    isempty(class(o)) || (out[:class] = string(class(o)))
    return out
end
Base.iterate(o::Attributes, state...) = iterate(LittleDict(o), state...)

function Base.getindex(o::Attributes, k::Symbol)
    k == :style && return style(o)
    k == :class && return class(o)
    return get(others(o), k, nothing)
end
function Base.setindex!(o::Attributes, v, k::Symbol)
    k == :style && return merge!(style(o), Style(v))
    k == :class && return merge!(class(o), Class(v))
    others(o)[k] = v
end
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
    function Element(name, attr, children)
        options.element_validate && name in keys(ELEMENTS) || throw(ArgumentError(styled"{red:<$name>} is not a valid HTML element."))
        new(name, attr, children)
    end
end
Element(name::Symbol) = Element(name, Attributes(), Children())

(o::Element)(x...; kw...) = Element(name(o), merge(attrs(o), Attributes(; kw...)), append!(children(o), x))

name(o::Element) = getfield(o, :name)
attrs(o::Element) = getfield(o, :attributes)
children(o::Element) = getfield(o, :children)

Base.copy(o::Element) = Element(name(o), copy(attrs(o)), copy(children(o)))

Base.propertynames(o::Element) = union(GLOBAL_ATTRIBUTES, ELEMENTS[name(o)].attributes)
Base.getproperty(o::Element, k::Symbol) = attrs(o)[k]
Base.setproperty!(o::Element, k::Symbol, v) = attrs(o)[k] = v

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
iframe(children...; kw...) = Element(:iframe, Attributes(; kw..., srcdoc=escape(repr("text/html", Children(children...)))), Children())

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


# #-----------------------------------------------------------------------------# parser
# include("parser.jl")

end #module
