module Cobweb

using DefaultApplication
using OrderedCollections: OrderedDict
using StyledStrings

export Page, Document, Style, Class, Attributes, Element,
    escape, unescape, escape!, unescape!, help, h, iframe

#-----------------------------------------------------------------------------# init
DIR::String = ""
INDEX::String = ""

function __init__()
    global DIR = mktempdir()
    global INDEX = joinpath(DIR, "index.html")
end

#-----------------------------------------------------------------------------# consts
"Mapping of special characters to their HTML entity equivalents."
const ESCAPE_CHARS = ('&' => "&amp;", '"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;")

"HTML5 void elements, e.g. `<br>`, `<img>`, `<input>`, etc."
const VOID_ELEMENTS = (:area,:base,:br,:col,:embed,:hr,:img,:input,:link,:meta,:param,:source,:track,:wbr)

"CSS units for absolute or relative lengths"
const CSS_UNITS = (:ch,:cm,:em,:ex,:fr,:in,:mm,:pc,:percent,:pt,:px,:rem,:vh,:vmax,:vmin,:vw)

include("Reference.jl")

#-----------------------------------------------------------------------------# (un)escape
"""
    escape(x::AbstractString)

Escape special characters in `x` to their HTML entity equivalents:

- $(join(ESCAPE_CHARS, "\n- "))
"""
escape(x::AbstractString) = replace(x, ESCAPE_CHARS...)

"""
    unescape(x::AbstractString)

Unescape HTML entities in `x` to their special character equivalents:

- $(join(reverse.(ESCAPE_CHARS), "\n- "))
"""
unescape(x::AbstractString) = replace(x, reverse.(ESCAPE_CHARS)...)

"""
    escape!(x)

Replace `children(x)` with `escape.(children(x))`.
"""
escape!(x) = (children(x) .= escape.(children(x)); return x)

"""
    unescape!(x)

Replace `children(x)` with `unescape.(children(x))`.
"""
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
"""
    Document(x)

An HTML document.  It's assumed the first element is `<html>`.
"""
struct Document
    x
end
function Base.show(io::IO, ::MIME"text/html", d::Document)
    print(io, "<!DOCTYPE html>")
    show(io, MIME"text/html"(), showable("text/html", d.x) ? d.x : HTML(d.x))
end

#-----------------------------------------------------------------------------# webdocs
"""
    help(element)
    help.element

Open the MDN documentation for `element` in a web browser.
"""
help(x::Symbol) = DefaultApplication.open("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/$x")
Base.getproperty(::typeof(help), x::Symbol) = help(x)
Base.propertynames(::typeof(help)) = keys(Reference.ELEMENTS)

#-----------------------------------------------------------------------------# Settings
"""
Global settings for Cobweb.
"""
baremodule Settings
    using Base: Set

    "Cobweb.jl should verify valid HTML5 elements are used."
    check_elements::Bool = true

    "Cobweb.jl should verfify valid HTML5 attributes are used for a given element."
    check_attributes::Bool = true

    "Cobweb.jl should verify all classes come from Settings.classes"
    check_classes::Bool = false
    classes::Set{Symbol} = Set()

    "Styles that should be tab-autocompleteable."
    style_properties::Set{Symbol} = Set()

    "Cobweb.jl should allow deprecated elements to be used."
    allow_deprecated_elements::Bool = false

    "Cobweb.jl should allow deprecated attributes to be used."
    allow_deprecated_attributes::Bool = false
end

#-----------------------------------------------------------------------------# KV
# Wrapper of an OrderedDict{Symbol, String} to represent key-value pairs.
# Returns `nothing` if a valid key is used, but not present in the dictionary.
abstract type KV <: AbstractDict{Symbol, Union{Nothing, String}} end
dict(o::KV) = getfield(o, :dict)
Base.propertynames(o::KV) = keys(o)
Base.getproperty(o::KV, x::Symbol) = getindex(o, x)
Base.setproperty!(o::KV, x::Symbol, v) = setindex!(o, v, x)
for f in (:length, :iterate, :get)
    @eval Base.$f(o::KV, x...) = $f(dict(o), x...)
end
dict(kw) = OrderedDict(Symbol(k) => string(v) for (k, v) in pairs(kw))
Base.merge!(a::T, b::T) where {T <: KV} = (merge!(dict(a), dict(b)); return a)
Base.merge(a::T, b::T) where {T <: KV} = T(merge(dict(a), dict(b)))
Base.:(==)(a::T, b::T) where {T <: KV} = dict(a) == dict(b)

#-----------------------------------------------------------------------------# Style
"""
    Style(; kw...)
    Style(s::AbstractString)

A style object that can be used to set CSS properties for an `Element`.  It is an `AbstractDict{Symbol, String}` with `property => value` entries.
Properties can be accessed with `o.property` and set with `o.property = value`.
"""
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
Base.setindex!(o::Style, v, x::Symbol) = setindex!(dict(o), string(v), x)
Base.print(io::IO, s::Style) = join(io, ("$k:$v" for (k, v) in s), ';')
Base.show(io::IO, ::MIME"text/html", s::Style) = print(io, '"', s, '"')


#-----------------------------------------------------------------------------# Class
"""
    Class(x...)

A class object that can be used to set CSS classes for an `Element`.
"""
mutable struct Class <: AbstractSet{Symbol}
    set::Set{Symbol}
end
Class(x::Symbol...) = Class(Set(x))
Class(x::Class) = x
Class(x::AbstractString) = Class(Symbol.(split(x, ' '; keepempty=false))...)
Class(x::AbstractString, xs::AbstractString...) = Class(join((x, xs...), ' '))

set(o::Class) = getfield(o, :set)

Base.iterate(o::Class, x...) = iterate(set(o), x...)
Base.length(o::Class) = length(set(o))
Base.push!(o::Class, x) = push!(set(o), Symbol(x))
Base.delete!(o::Class, x) = delete!(set(o), Symbol(x))
Base.in(x, o::Class) = in(Symbol(x), set(o))
Base.copy(o::Class) = Class(copy(set(o)))
Base.empty!(o::Class) = (empty!(set(o)); o)
Base.print(io::IO, c::Class) = join(io, sort!(collect(c)), ' ')
Base.show(io::IO, ::MIME"text/html", c::Class) = print(io, '"', c, '"')

#-----------------------------------------------------------------------------# Attributes
"""
    Attributes(; kw...)

An attributes object that can be used to set HTML attributes for an `Element`.  It is an `AbstractDict{Symbol, Union{Nothing, String}}`.
Internally, it contains a `Style` object for CSS properties and a `Class` object for CSS classes.
The `style` and `class` keyword arguments can be used with a String or a `Style`/`Class` object, respectively.
"""
mutable struct Attributes <: KV
    style::Style
    class::Class
    dict::OrderedDict{Symbol, Union{String}}
    element::Symbol
    function Attributes(element=:unknown; style=Style(), class=Class(), kw...)
        o = new(Style(style), Class(class), dict(kw), element)
        foreach(k -> check_key(o, k), keys(kw))
        return o
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
Base.print(io::IO, o::Attributes) = join(io, (v=="true" ? k : " $k=$(repr(v))" for (k,v) in o))
Base.show(io::IO, ::MIME"text/html", o::Attributes) = print(io, o)

#-----------------------------------------------------------------------------# Element
"""
    Element(tag, children...; kw...)

An HTML element.  Typically created by using the `Cobweb.h` function.
"""
struct Element <: AbstractVector{Any}
    tag::Symbol
    attributes::Attributes
    children::Vector{Any}
    function Element(tag::Symbol, attributes::Attributes, children::Vector)
        tag in VOID_ELEMENTS && !isempty(children) && error("void element $tag cannot have children.")
        setfield!(attributes, :element, tag)
        new(tag, attributes, Any[children...])
    end
end
tag(o::Element) = getfield(o, :tag)
attributes(o::Element) = getfield(o, :attributes)
children(o::Element) = getfield(o, :children)

function Base.summary(io::IO, o::Element)
    n = length(o)
    child_info = tag(o) in VOID_ELEMENTS ?
        styled" {bright_black:(void element)}" :
        styled""" {bright_black:($n $(n == 1 ? "child" : "children"))}"""
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


#-----------------------------------------------------------------------------# parsing
Base.parse(::Type{Style}, x::AbstractString) = Style(x)
Base.parse(::Type{Class}, x::AbstractString) = Class(x)
Base.parse(::Type{Attributes}, x::AbstractString) = Attributes(x)


end # module
