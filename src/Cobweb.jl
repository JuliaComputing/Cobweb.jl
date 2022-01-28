module Cobweb

using DefaultApplication: DefaultApplication
using Scratch: @get_scratch!

#-----------------------------------------------------------------------------# init
htmlfile = ""  # path to cobweb.html
struct CobwebDisplay <: AbstractDisplay end

function __init__()
    global htmlfile = touch(joinpath(@get_scratch!("CobWeb"), "cobweb.html"))
    pushdisplay(CobwebDisplay())
end

#-----------------------------------------------------------------------------# Node
struct Node
    tag::String
    attrs::Dict{String,String}
    children::Vector
    function Node(tag, attrs, children)
        new(tag, attrs, children)
    end
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

function Base.getproperty(::typeof(h), tag::Symbol)
    f(children...; kw...) = h(String(tag), children...; kw...)
    return f
end

#-----------------------------------------------------------------------------# escapeHTML
# Taken from HTTPCommon.jl (ref: http://stackoverflow.com/a/7382028/3822752)
function escape_html(x::String)
    replace(x,  "&"=>"&amp;", "\""=>"&quot;",  "'"=>"&#39;",  "<"=>"&lt;",  ">"=>"&gt;")
end

#-----------------------------------------------------------------------------# show (html)
pretty(x) = (io = IOBuffer(); pretty(io, x); String(take!(io)))

pretty(io::IO, node::Node) = show(IOContext(io, :pretty=>true), node)

function Base.show(io::IO, node::Node)
    color = get(io, :tagcolor, 1)
    pretty = get(io, :pretty, false)
    level = pretty ? get(io, :level, 0) : 0
    indent = pretty ? ' ' ^ get(io, :indent, 2) : ""
    p(args...) = printstyled(io, args...; color)
    p(indent ^ level, '<', node.tag)
    for (k,v) in node.attrs
        if v == "true"
            p(' ', k)
        elseif v == "false"
        else
            p(' ', k, '=', '"', v, '"')
        end
    end
    p('>')
    has_node_children = any(x -> x isa Node, node.children)
    pretty && has_node_children && p('\n')
    n_nodes = 0
    for (i, child) in enumerate(node.children)
        if child isa String
            has_node_children ?
                p(indent ^ (level + 1), escape_html(child), '\n') :
                p(escape_html(child))
        elseif child isa Node
            show(IOContext(io, :tagcolor => color + i + n_nodes, :level => level+1), MIME("text/html"), child)
            n_nodes = sum(x -> x isa Node, child.children, init=0)
        else
            show(io, MIME("text/html"), child)
        end
    end
    if has_node_children
        p(indent ^ level, "</", node.tag, '>')
    else
        p("</", node.tag, '>')
    end
    pretty && println(io)
end
Base.show(io::IO, ::MIME"text/html", node::Node) = show(io, node)

#-----------------------------------------------------------------------------# show (javascript)
function Base.show(io::IO, M::MIME"text/javascript", node::Node)
    print(io, "m(\"", node.tag, "\", ")
    write_javascript(io, node.attrs)
    for child in node.children
        print(io, ", ")
        write_javascript(io, child)
    end
    print(io, ")")
end

write_javascript(io::IO, x::Node) = show(io, MIME"text/javascript"(), x)
write_javascript(io::IO, ::Nothing) = print(io, "null")
write_javascript(io::IO, x::String) = print(io, '"', x, '"')
write_javascript(io::IO, x::Union{Bool, Real}) = print(io, x)
function write_javascript(io, x::AbstractDict)
    if isempty(x)
        print(io, "null")
    else
        print(io, '{')
        for (i,(k,v)) in enumerate(x)
            print(io, k, ':')
            write_javascript(io, v)
            i != length(x) && print(io, ", ")
        end
        print(io,'}')
    end
end

#-----------------------------------------------------------------------------# Page
struct Page
    node::Node
end

function writehtml(page::Page)
    Base.open(htmlfile, "w") do io
        println(io, "<!doctype html>")
        show(io, MIME("text/html"), page.node)
    end
end

function Base.display(::CobwebDisplay, page::Page)
    writehtml(page)
    DefaultApplication.open(htmlfile)
end

end #module
