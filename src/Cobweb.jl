module Cobweb

using DefaultApplication: DefaultApplication
using Scratch: @get_scratch!
using OrderedCollections: OrderedDict

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
    attrs::OrderedDict{String,String}
    children::Vector
    function Node(tag::AbstractString, attrs::AbstractDict, children::AbstractVector)
        new(string(tag), OrderedDict(string(k) => string(v) for (k,v) in pairs(attrs)), collect(children))
    end
end
tag(o::Node) = getfield(o, :tag)
attrs(o::Node) = getfield(o, :attrs)
children(o::Node) = getfield(o, :children)

attrs(kw::Base.Pairs) = OrderedDict(string(k) => string(v) for (k,v) in kw)

(o::Node)(x...; kw...) = Node(tag(o), merge(attrs(o), attrs(kw)), vcat(children(o), x...))

Base.:(==)(a::Node, b::Node) = all(f(a) == f(b) for f in (tag, attrs, children))

# append classes
Base.getproperty(o::Node, class::String) = o(class = lstrip(get(o, :class, "") * " " * class))

# methods that pass through to attrs(o)
Base.propertynames(o::Node) = Symbol.(keys(o))
Base.getproperty(o::Node, name::Symbol) = attrs(o)[string(name)]
Base.setproperty!(o::Node, name::Symbol, x) = attrs(o)[string(name)] = string(x)
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
h(tag, children...; kw...) = Node(tag, attrs(kw), collect(children))

h(tag, attrs::AbstractDict, children...) = Node(tag, attrs, collect(children))

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
    p(args...) = print(io, args...)
    p('<', tag(node))
    for (k,v) in attrs(node)
        v == "true" ? p(' ', k) : v != "false" && p(' ', k, '=', '"', v, '"')
    end
    p('>')
    for child in children(node)
        showable("text/html", child) ? show(io, MIME("text/html"), child) : p(child)
    end
    p("</", tag(node), '>')
end

Base.show(io::IO, ::MIME"text/html", node::Node) = show(io, node)
Base.show(io::IO, ::MIME"text/xml", node::Node) = show(io, node)
Base.show(io::IO, ::MIME"application/xml", node::Node) = show(io, node)

#-----------------------------------------------------------------------------# show (javascript)
struct Javascript
    x::String
end
Base.show(io::IO, ::MIME"text/javascript", j::Javascript) = print(io, j.x)
Base.show(io::IO, ::MIME"text/html", j::Javascript) = print(io, "<script>", j.x, "</script>")

#-----------------------------------------------------------------------------# CSS
"""
    CSS(::AbstractDict)

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
    content::OrderedDict{String, OrderedDict{String,String}}
    function CSS(o::AbstractDict)
        new(OrderedDict(string(k) => OrderedDict(string(k2) => string(v2) for (k2,v2) in pairs(v)) for (k,v) in pairs(o)))
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
Base.show(io::IO, ::MIME"text/html", o::CSS) = show(io, h.style(repr("text/css", o)))
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
    function Page(content)
        is_html = showable("text/html", content)
        !is_html && @warn "Content ($(typeof(content))) does not have an HTML representation.  Returning `Page(HTML(content))`."
        new(is_html ? content : HTML(content))
    end
end
Page(pg::Page) = pg

save(file::String, page::Page) = save(page, file)

function save(page::Page, file=joinpath(DIR, "index.html"))
    Base.open(io -> show(io, page), touch(file), "w")
    file
end

function Base.show(io::IO, o::Page)
    show(io, Doctype())
    show(io, MIME("text/html"), o.content)
end

Base.show(io::IO, ::MIME"text/html", page::Page) = show(io, page)

Base.display(::CobwebDisplay, page::Page) = DefaultApplication.open(save(page))

#-----------------------------------------------------------------------------# Tab
struct Tab
    content
end
Base.display(::CobwebDisplay, t::Tab) = DefaultApplication.open(save(Page(t.content), tempname() * ".html"))

#-----------------------------------------------------------------------------# IFrame
"""
    IFrame(content; kw...)

Create an `<iframe srcdoc = [content] kw...>`.
"""
struct IFrame
    page::Page
    kw
end
IFrame(content; kw...) = IFrame(content isa Page ? content : Page(content), kw)

Base.show(io::IO, o::IFrame) = show(io, h.iframe(; srcdoc=escape(string(o.page)), o.kw...))
Base.show(io::IO, ::MIME"text/html", o::IFrame) = show(io, o)

function iframe(x; height=250, width=750, kw...)
    Base.depwarn("Cobweb.iframe(x) is deprecated.  Use `Cobweb.IFrame(x)` instead.", :iframe; force=true)
    IFrame(x; height=height, width=width, kw...)
end

include("parser.jl")

end #module
