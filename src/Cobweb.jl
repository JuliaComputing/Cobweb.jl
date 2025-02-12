module Cobweb

using DefaultApplication
using OrderedCollections: OrderedDict
using StyledStrings

export Page, Document, Style, Class, Attributes, Element, escape, unescape, escape!, unescape!

#-----------------------------------------------------------------------------# init
DIR::String = ""
INDEX::String = ""

function __init__()
    global DIR = mktempdir()
    global INDEX = joinpath(DIR, "index.html")
end

#-----------------------------------------------------------------------------# consts
const ESCAPE_CHARS = ('&' => "&amp;", '"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;")
const VOID_ELEMENTS = (:area,:base,:br,:col,:embed,:hr,:img,:input,:link,:meta,:param,:source,:track,:wbr)
const CSS_UNITS = (:ch,:cm,:em,:ex,:fr,:in,:mm,:pc,:percent,:pt,:px,:rem,:vh,:vmax,:vmin,:vw)

include("Reference.jl")

#-----------------------------------------------------------------------------# (un)escape
escape(x::AbstractString) = replace(x, ESCAPE_CHARS...)
unescape(x::AbstractString) = replace(x, reverse.(ESCAPE_CHARS)...)
escape!(x) = (children(x) .= escape.(children(x)); return x)
unescape!(x) = (children(x) .= unescape.(children(x)); return x)

#-----------------------------------------------------------------------------# Page
"""
    Page(x)

`Base.display` `x` in a web browser using its `MIME"text/html"` representation.
"""
struct Page
    x
end
function Base.show(io::IO, p::Page)
    open(INDEX, "w") do io
        show(io, MIME"text/html"(), showable("text/html", p.x) ? p.x : HTML(p.x))
    end
    DefaultApplication.open(INDEX)
end

#-----------------------------------------------------------------------------# Document
struct Document
    x
end
function Base.show(io::IO, ::MIME"text/html", d::Document)
    print(io, "<!DOCTYPE html>")
    show(io, MIME"text/html"(), showable("text/html", d.x) ? d.x : HTML(d.x))
end

#-----------------------------------------------------------------------------# webdocs
help(x::Symbol) = DefaultApplication.open("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/$x")
Base.getproperty(::typeof(help), x::Symbol) = help(x)
Base.propertynames(::typeof(help)) = keys(Reference.ELEMENTS)

#-----------------------------------------------------------------------------# Settings
baremodule Settings
    using Base: Set

    "Cobweb.jl should verify valid HTML5 elements are used."
    check_elements::Bool = true

    "Cobweb.jl should verfify valid HTML5 attributes are used for a given element."
    check_attributes::Bool = true

    "Cobweb.jl should verify all classes come from Settings.classes"
    check_classes::Bool = false
    classes::Set{Symbol} = Set()

    style_properties::Set{Symbol} = Set()

    "Cobweb.jl should allow deprecated elements to be used."
    allow_deprecated_elements::Bool = false

    "Cobweb.jl should allow deprecated attributes to be used."
    allow_deprecated_attributes::Bool = false
end  # Settings module

#-----------------------------------------------------------------------------# KV
# Wrapper of an OrderedDict{Symbol, String} to represent key-value pairs.
# Returns `nothing` if a valid key is used, but not present in the dictionary.
abstract type KV <: AbstractDict{Symbol, Union{Nothing, String}} end
dict(o::KV) = getfield(o, :dict)
Base.propertynames(o::KV) = keys(o)
Base.getproperty(o::KV, x::Symbol) = getindex(o, x)
Base.setproperty!(o::KV, x::Symbol, v) = setindex!(o, v, x)
for f in (:length, :iterate)
    @eval Base.$f(o::KV, x...) = $f(dict(o), x...)
end
dict(kw) = OrderedDict(Symbol(k) => string(v) for (k, v) in pairs(kw))

#-----------------------------------------------------------------------------# Style
mutable struct Style <: KV
    dict::OrderedDict{Symbol, String}
end
Style(; kw...) = Style(dict(kw))
Style(x::Style) = x
function Style(s::AbstractString)
    out = Style()
    for entry in split(s, ';'; keepempty=false)
        k, v = split(entry, ':'; keepempty=false)
        setproperty!(out, Symbol(strip(k)), strip(v))
    end
    return out
end
Base.keys(o::Style) = union(keys(dict(o)), Settings.style_properties)
Base.getindex(o::Style, x::Symbol) = get(dict(o), x, nothing)
Base.setindex!(o::Style, v, x::Symbol) = setindex!(dict(o), v, x)
Base.print(io::IO, s::Style) = join(io, ("$k:$v" for (k, v) in s), ';')
Base.show(io::IO, ::MIME"text/html", s::Style) = print(io, '"', s, '"')


#-----------------------------------------------------------------------------# Class
mutable struct Class <: AbstractSet{Symbol}
    set::Set{Symbol}
end
Class(x::Symbol...) = Class(Set(x))
Class(x::Class) = x
Class(x::AbstractString) = Class(Symbol.(split(x, ' '; keepempty=false))...)
for f in (:iterate, :length, :push!, :delete!)
    @eval Base.$f(o::Class, x...) = $f(getfield(o, :set), x...)
end
Base.print(io::IO, c::Class) = join(io, c, ' ')
Base.show(io::IO, ::MIME"text/html", c::Class) = print(io, '"', c, '"')

#-----------------------------------------------------------------------------# Attributes
mutable struct Attributes <: KV
    style::Style
    class::Class
    dict::OrderedDict{Symbol, Union{String}}
    element::Symbol
    function Attributes(element=:unknown; style=Style(), class=Class(), kw...)
        new(Style(style), Class(class), dict(kw), element)
    end
end
style(o::Attributes) = getfield(o, :style)
class(o::Attributes) = getfield(o, :class)
Base.keys(o::Attributes) = union(get(Reference.ELEMENTS, getfield(o, :element), Symbol[]), Reference.GLOBAL_ATTRIBUTES)
check_key(o::Attributes, x::Symbol) = Settings.check_attributes && x ∉ keys(o) ? error(":$x is not a valid attribute for element :$(getfield(o, :element)).") : x
Base.getindex(o::Attributes, x::Symbol) = check_key(o, x) in (:style, :class) ? getfield(o, x) : get(dict(o), x, nothing)
Base.setindex!(o::Attributes, v, x::Symbol) = check_key(o, x) == :style ? setfield!(o, x, Style(v)) :
    x == :class ? setfield!(o, x, Class(v)) :
    setindex!(dict(o), v, x)
Base.length(o::Attributes) = length(dict(o)) + length(o.style) + length(o.class)
Base.iterate(o::Attributes) = Base.iterate(o, -1)
function Base.iterate(o::Attributes, i)
    i == -1 && return !isempty(style(o)) ? (:style => string(style(o)), 0) : iterate(o, 0)
    i == 0 && return !isempty(class(o)) ? (:class => string(class(o)), 1) : iterate(o, 1)
    return iterate(dict(o), i)
end
Base.print(io::IO, o::Attributes) = join(io, (v=="true" ? v : " $k=$(repr(v))" for (k,v) in o), ' ')


#-----------------------------------------------------------------------------# Element
struct Element{T} <: AbstractVector{Union{T, AbstractString}}
    tag::Symbol
    attributes::Attributes
    children::Vector{T}
    function Element(tag::Symbol, attributes::Attributes, children::Vector{T}) where {T}
        tag in VOID_ELEMENTS && !isempty(children) && error("void element $tag cannot have children.")
        setfield!(attributes, :element, tag)
        new{T}(tag, attributes, children)
    end
end
tag(o::Element) = getfield(o, :tag)
attributes(o::Element) = getfield(o, :attributes)
children(o::Element) = getfield(o, :children)

function Base.summary(io::IO, o::Element{T}) where {T}
    n = length(o)
    child_info = tag(o) in VOID_ELEMENTS ?
        styled" {bright_black:(void element)}" :
        styled""" {bright_black:($n $(n == 1 ? "child" : "children") of type $T)}"""
    print(io, "<", tag(o), attributes(o), ">", child_info)
end
Element(tag, children...; kw...) = Element(Symbol(tag), Attributes(; kw...), isempty(children) ? [] : collect(children))
# methods that simply pass through to children
for f in (:length, :size, :iterate, :getindex, :setindex!)
    @eval Base.$f(o::Element, x...) = $f(children(o), x...)
end
# methods that return the AbstractArray
for f in (:push!, :resize!, :deleteat!)
    @eval function Base.$f(o::Element, x)
        tag(o) in VOID_ELEMENTS && error("Cannot add children to void element :$(tag(o)).")
        $f(children(o), x)
    end
end
function (o::Element)(children...; kw...)
    push!(o, children...)
    for (k, v) in pairs(kw)
        setproperty!(o, k, v)
    end
    return o
end

# properties pass through to attributes
Base.propertynames(o::Element) = propertynames(attributes(o))
Base.getproperty(o::Element, x::Symbol) = getproperty(attributes(o), x)
Base.setproperty!(o::Element, x::Symbol, v) = setproperty!(attributes(o), x, v)

function Base.show(io::IO, ::MIME"text/html", o::Element)
    tag(o) in VOID_ELEMENTS ?
        print(io, '<', tag(o), attributes(o), '>') :
        print(io, '<', tag(o), attributes(o), '>', children(o)..., "</", tag(o), '>')
end

#-----------------------------------------------------------------------------# h
h(tag, children...; kw...) = Element(Symbol(tag), children...; kw...)
Base.propertynames(::typeof(h)) = keys(Reference.ELEMENTS)
Base.getproperty(::typeof(h), x::Symbol) = h(x)

#-----------------------------------------------------------------------------# iframe
iframe(children...; kw...) = h.iframe(; kw..., srcdoc = join(escape(repr("text/html", x)) for x in children))

end # module
