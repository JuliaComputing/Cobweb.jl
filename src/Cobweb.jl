module Cobweb

using DefaultApplication: DefaultApplication
using Scratch: @get_scratch!

#-----------------------------------------------------------------------------# init
struct CobwebDisplay <: AbstractDisplay end

function __init__()
    global DIR = @get_scratch!("CobWeb")
    pushdisplay(CobwebDisplay())
end

#-----------------------------------------------------------------------------# File
struct File
    path::String
    builddir::String
    File(path::String, builddir::String = "assets/") = new(path, builddir)
end
Base.show(io::IO, file::File) = file.buildir * file.path

#-----------------------------------------------------------------------------# Node
struct Node
    tag::String
    attrs::Dict{String,Union{File, String}}
    children::Vector
    function Node(tag, attrs, children)
        new(tag, attrs, children)
    end
end

function Base.getproperty(node::Node, class::String)
    node.attrs["class"] = class
    node
end

get_attrs(kw) = Dict(string(k) => v isa File ? v : string(v) for (k,v) in kw)

(node::Node)(children...; kw...) = Node(node.tag, merge(node.attrs, get_attrs(kw)), vcat(node.children, children...))

#-----------------------------------------------------------------------------# h
h(tag, children...; kw...) = Node(tag, get_attrs(kw), collect(children))

h(tag, attrs::Dict, children...) = Node(tag, attrs, collect(children))

function Base.getproperty(::typeof(h), tag::Symbol)
    f(children...; kw...) = h(String(tag), children...; kw...)
    return f
end

macro h(ex)
    esc(_h(ex))
end

function _h(ex::Expr)
    for i in 1:length(ex.args)
        x = ex.args[i]
        if x isa Expr
            ex.args[i] = _h(x)
        elseif x isa Symbol
            ex.args[i] = Expr(:., :(Cobweb.h), QuoteNode(ex.args[1]))
        end
    end
    ex
end

#-----------------------------------------------------------------------------# escapeHTML
# Taken from HTTPCommon.jl (ref: http://stackoverflow.com/a/7382028/3822752)
function escape_html(x::String)
    s = replace(x,  "&"=>"&amp;")
    s = replace(s, "\""=>"&quot;")
    s = replace(s, "'"=>"&#39;")
    s = replace(s, "<"=>"&lt;")
    replace(s, ">"=>"&gt;")
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
struct Javascript
    x::String
end
Base.show(io::IO, ::MIME"text/javascript", j::Javascript) = print(io, j.x)

function Base.show(io::IO, M::MIME"text/javascript", node::Node)
    print(io, "m(\"", node.tag, "\", ")
    write_javascript(io, node.attrs)
    for child in node.children
        print(io, ", ")
        write_javascript(io, child)
    end
    print(io, ")")
end

write_javascript(io::IO, x) = show(io, MIME"text/javascript"(), x)

write_javascript(io::IO, ::Nothing) = print(io, "null")
write_javascript(io::IO, x::String) = print(io, '"', x, '"')
write_javascript(io::IO, x::Union{Bool, Real}) = print(io, x)
function write_javascript(io::IO, x::AbstractDict)
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
function Base.show(io::IO, ::MIME"text/html", o::CSS)
    println(io, "<style>")
    print(io, o)
    println(io, "</style>")
end

#-----------------------------------------------------------------------------# Page
struct Page
    content
    route::String
    Page(content, route="/") = new(content, route)
end
function scratch_file(page::Page)
    dir = mkpath(joinpath(DIR, split(page.route, '/', keepempty=false)...))
    touch(joinpath(dir, "index.html"))
end

save(file::String, page::Page) = save(page, file)

function save(page::Page, file=scratch_file(page))
    Base.open(file, "w") do io
        println(io, "<!doctype html>")
        show(io, MIME("text/html"), page.content)
    end
    file
end

function Base.display(::CobwebDisplay, page::Page)
    save(page)
    DefaultApplication.open(scratch_file(page))
end

end #module
