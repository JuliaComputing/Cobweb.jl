module Cobweb

using DefaultApplication: DefaultApplication
using Scratch: @get_scratch!
using StructTypes

export Page

#-----------------------------------------------------------------------------# init
struct CobwebDisplay <: AbstractDisplay end

function __init__()
    global DIR = @get_scratch!("CobWeb")
    pushdisplay(CobwebDisplay())
end

#-----------------------------------------------------------------------------# Node
struct Node
    tag::String
    attrs::Dict{String,String}
    children::Vector
end

function Base.:(==)(a::Node, b::Node)
    a.tag == b.tag &&
        a.attrs == b.attrs &&
        length(a.children) == length(b.children) &&
        all(ac == bc for (ac,bc) in zip(a.children, b.children))
end

function Base.getproperty(node::Node, class::String)
    node.attrs["class"] = class
    node
end

get_attrs(kw) = Dict(string(k) => string(v) for (k,v) in kw)

(node::Node)(children...; kw...) = Node(node.tag, merge(node.attrs, get_attrs(kw)), vcat(node.children, children...))

#-----------------------------------------------------------------------------# h
h(tag, children...; kw...) = Node(tag, get_attrs(kw), collect(children))

h(tag, attrs::Dict, children...) = Node(tag, attrs, collect(children))

Base.getproperty(::typeof(h), tag::Symbol) = h(string(tag))

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
# Taken from HTTPCommon.jl (ref: http://stackoverflow.com/a/7382028/3822752)
escape_html(x) = replace(string(x), '&' => "&amp;",'"' => "&quot;", ''' => "&#39;", '<' => "&lt;", '>' => "&gt;")

#-----------------------------------------------------------------------------# show (html)
function Base.show(io::IO, node::Node)
    color = get(io, :tagcolor, 1)
    p(args...) = printstyled(io, args...; color)
    # opening tag
    p('<', node.tag,)
    for (k,v) in node.attrs
        if v == "true"
            p(' ', k)
        elseif v != "false"
            p(' ', k, '=', '"', v, '"')
        end
    end
    p('>')
    # children
    for (i, child) in enumerate(node.children)
        if child isa Union{AbstractString, Number, Symbol}
            p(child)
        else
            show(IOContext(io, :tagcolor => color + i), MIME("text/html"), child)
        end
    end
    # closing tag
    p("</", node.tag, '>')
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

#-----------------------------------------------------------------------------# Page
struct Page
    content
end
Page(pg::Page) = pg

save(file::String, page::Page) = save(page, file)

function save(page::Page, file=joinpath(DIR, "index.html"))
    Base.open(touch(file), "w") do io
        println(io, "<!doctype html>")
        show(io, MIME("text/html"), page.content)
    end
    file
end

Base.display(::CobwebDisplay, page::Page) = DefaultApplication.open(save(page))

#-----------------------------------------------------------------------------# StructTypes
StructTypes.StructType(::Type{Node})        = StructTypes.Struct()
StructTypes.StructType(::Type{Javascript})  = StructTypes.Struct()
StructTypes.StructType(::Type{CSS})         = StructTypes.Struct()
StructTypes.StructType(::Type{Page})        = StructTypes.Struct()

end #module
