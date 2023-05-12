module Cobweb

using DefaultApplication: DefaultApplication
using Scratch: @get_scratch!
using StructTypes
using Random

export Page, Tab

#-----------------------------------------------------------------------------# init
struct CobwebDisplay <: AbstractDisplay end

function __init__()
    global DIR = @get_scratch!("CobWeb")
    pushdisplay(CobwebDisplay())
end

#-----------------------------------------------------------------------------# Node
"""
    Node(tag::String, attrs::Dict{String,String}, children::Vector)

Should not often be used directly.  See `?Cobweb.h`.
"""
struct Node
    tag::String
    attrs::Dict{String,String}
    children::Vector
end
tag(o::Node) = getfield(o, :tag)
attrs(o::Node) = getfield(o, :attrs)
children(o::Node) = getfield(o, :children)


function Base.:(==)(a::Node, b::Node)
    tag(a) == tag(b) &&
        attrs(a) == attrs(b) &&
        length(children(a)) == length(children(b)) &&
        all(ac == bc for (ac,bc) in zip(children(a), children(b)))
end

function Base.getproperty(node::Node, class::String)
    d = attrs(node)
    if haskey(d, "class")
        d["class"] = d["class"] * " $class"
    else
        d["class"] = class
    end
    node
end

Base.getproperty(node::Node, name::Symbol) = getfield(node, :attrs)[string(name)]
Base.setproperty!(node::Node, name::Symbol, x) = getfield(node, :attrs)[string(name)] = string(x)

Base.getindex(node::Node, i::Integer) = children(node)[i]
Base.setindex!(node::Node, x, i::Integer) = setindex!(children(node), x, i)

get_attrs(kw) = Dict(string(k) => string(v) for (k,v) in kw)

(node::Node)(x...; kw...) = Node(tag(node), merge(attrs(node), get_attrs(kw)), vcat(children(node), x...))

#-----------------------------------------------------------------------------# h
"""
    h(tag, children...; kw...)
    h.tag(children...; kw...)
    h.tag."classes"(children...; kw...)

Create an html node with the given `tag`, `children`, and `kw` attributes.

### Examples

    h.div("child", class="myclass", id="myid")
    # <div class="myclass" id="myid">child</div>

    h.div."myclass"("content")
    # <div class="myclass">content</div>
"""
h(tag, children...; kw...) = Node(tag, get_attrs(kw), collect(children))

h(tag, attrs::Dict, children...) = Node(tag, attrs, collect(children))

Base.getproperty(::typeof(h), tag::Symbol) = h(string(tag))
Base.propertynames(::typeof(h)) = HTML5_TAGS

#-----------------------------------------------------------------------------# @h
HTML5_TAGS = [:a,:abbr,:address,:area,:article,:aside,:audio,:b,:base,:bdi,:bdo,:blockquote,:body,:br,:button,:canvas,:caption,:cite,:code,:col,:colgroup,:data,:datalist,:dd,:del,:details,:dfn,:dialog,:div,:dl,:dt,:em,:embed,:fieldset,:figcaption,:figure,:footer,:form,:h1,:h2,:h3,:h4,:h5,:h6,:head,:header,:hgroup,:hr,:html,:i,:iframe,:img,:input,:ins,:kbd,:label,:legend,:li,:link,:main,:map,:mark,:math,:menu,:menuitem,:meta,:meter,:nav,:noscript,:object,:ol,:optgroup,:option,:output,:p,:param,:picture,:pre,:progress,:q,:rb,:rp,:rt,:rtc,:ruby,:s,:samp,:script,:section,:select,:slot,:small,:source,:span,:strong,:style,:sub,:summary,:sup,:svg,:table,:tbody,:td,:template,:textarea,:tfoot,:th,:thead,:time,:title,:tr,:track,:u,:ul,:var,:video,:wbr]

macro h(ex)
    esc(_h(ex))
end

function _h(ex::Expr)
    for i in 1:length(ex.args)
        x = ex.args[i]
        if x isa Expr
            ex.args[i] = _h(x)
        elseif x isa Symbol && x in HTML5_TAGS
            ex.args[i] = Expr(:., :(Cobweb.h), QuoteNode(ex.args[1]))
        end
    end
    ex
end
_h(x::Symbol) = x in HTML5_TAGS ? Expr(:., :(Cobweb.h), QuoteNode(x)) : x

#-----------------------------------------------------------------------------# escapeHTML
escape_chars = ['&' => "&amp;", '"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;"]
escape(x) = replace(string(x), escape_chars...)
unescape(x::AbstractString) = replace(x, reverse.(escape_chars)...)

#-----------------------------------------------------------------------------# show (html)
function Base.show(io::IO, node::Node)
    color = get(io, :tagcolor, 1)
    p(args...) = printstyled(io, args...; color)
    # opening tag
    p('<', tag(node))
    for (k,v) in attrs(node)
        if v == "true"
            p(' ', k)
        elseif v != "false"
            p(' ', k, '=', '"', v, '"')
        end
    end
    p('>')
    # children
    for (i, child) in enumerate(children(node))
        if child isa Union{AbstractString, Number, Symbol}
            p(child)
        else
            hasmethod(show, Tuple{IO, MIME"text/html", typeof(child)}) ?
                show(IOContext(io, :tagcolor => color + i), MIME("text/html"), child) :
                error("Child element of type `$(typeof(child))` does not have a text/html representation.")
        end
    end
    # closing tag
    p("</", tag(node), '>')
end

Base.show(io::IO, ::MIME"text/html", node::Node) = show(io, node)
Base.show(io::IO, ::MIME"text/xml", node::Node) = show(io, node)
Base.show(io::IO, ::MIME"application/xml", node::Node) = show(io, node)

pretty(args...) = error("The `pretty` function has been removed from Cobweb.")

#-----------------------------------------------------------------------------# show (javascript)
struct Javascript
    x::String
end
Base.show(io::IO, ::MIME"text/javascript", j::Javascript) = print(io, j.x)
Base.show(io::IO, ::MIME"text/html", j::Javascript) = print(io, "<script>", j.x, "</script>")

#-----------------------------------------------------------------------------# CSS
"""
    CSS(dictionary)

Write CSS with a nested dictionary with keys (`selector => (property => value)`).

### Example

    CSS(Dict(
        "p" => Dict(
            "font-family" => "Arial",
            "text-transform" => "uppercase"
        )
    ))
"""
struct CSS
    content::Dict{String, Dict{String,String}}
    function CSS(o::AbstractDict)
        new(Dict(string(k) => Dict(string(k2) => string(v2) for (k2,v2) in pairs(v)) for (k,v) in pairs(o)))
    end
end
function Base.show(io::IO, o::CSS)
    for (k,v) in o.content
        println(io, k, " {")
        for (k2, v2) in v
            println(io, "  ", k2, ':', ' ', v2, ';')
        end
        println(io, '}')
    end
end
Base.show(io::IO, ::MIME"text/css", o::CSS) = print(io, o)
function Base.show(io::IO, ::MIME"text/html", o::CSS)
    println(io, "<style>")
    print(io, o)
    println(io, "</style>")
end
save(file::String, o::CSS) = save(o, file)
save(o::CSS, file::String) = open(io -> show(io, x), touch(file), "w")

#-----------------------------------------------------------------------------# Doctype
"""
    Cobweb.Doctype()

Inserts into HTML as `<!doctype html>`.
"""
struct Doctype end
Base.show(io::IO, o::Doctype) = print(io, "<!doctype html>")
Base.show(io::IO, ::MIME"text/html", o::Doctype) = show(io, o)

#-----------------------------------------------------------------------------# Comment
"""
    Comment(x)

Inserts into HTML as `<!-- \$(string(x)) ->`.
"""
struct Comment
    x::String
    Comment(x) = new(string(x))
end
Base.show(io::IO, o::Comment) = print(io, "<!-- ", o.x, " -->")
Base.show(io::IO, ::MIME"text/html", o::Comment) = show(io, o)

#-----------------------------------------------------------------------------# Page
"""
    Page(content)

Wrapper to display `content` in your web browser.  Assumes `content` has an available
show method for `MIME("text/html")`.
"""
struct Page
    content
end
Page(pg::Page) = pg

save(file::String, page::Page) = save(page, file)

function save(page::Page, file=joinpath(DIR, "index.html"))
    Base.open(touch(file), "w") do io
        println(io, "<!doctype html>")
        try
            show(io, MIME("text/html"), page.content)
        catch
            println(io, page.content)
        end
    end
    file
end

Base.display(::CobwebDisplay, page::Page) = DefaultApplication.open(save(page))

#-----------------------------------------------------------------------------# Tab
struct Tab
    content
end
Base.display(::CobwebDisplay, t::Tab) = DefaultApplication.open(save(Page(t.content), tempname() * ".html"))

#-----------------------------------------------------------------------------# StructTypes
StructTypes.StructType(::Type{Node})        = StructTypes.Struct()
StructTypes.StructType(::Type{Javascript})  = StructTypes.Struct()
StructTypes.StructType(::Type{CSS})         = StructTypes.Struct()
StructTypes.StructType(::Type{Doctype})     = StructTypes.Struct()
StructTypes.StructType(::Type{Page})        = StructTypes.Struct()

#-----------------------------------------------------------------------------# IFrame
"""
    iframe(x)

Create an <iframe> (without a `src`) using the text/html representation of `x
Useful for embedding dynamically-generated content.
"""
function iframe(x; height=250, width=750)
    Base.depwarn("Cobweb.iframe(x; height, width) is deprecated.  Use Cobweb.h.iframe(; srcdoc=x, height, width) instead.", :iframe; force=true)
    x = x isa Union{AbstractString, Number, Symbol} ? HTML(string(x)) : x
    return h.iframe(; height, width, srcdoc=repr("text/html", x))
end

include("parser.jl")

end #module
