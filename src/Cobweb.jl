module Cobweb

using JSON3
using EasyConfig
using HTTP
using Sockets

#-----------------------------------------------------------------------------# AsIs
# A way to escape the MIMEtype
struct AsIs{T}
    x::T
end
print(io::IO, ::T, o::AsIs) where {T} = print(io, o.x)

#-----------------------------------------------------------------------------# Mithril
module Mithril
    using JSON3
    write(io::IO, x) = error("No Mithril representation for $(typeof(x)).")
    write(x) = (io = IOBuffer(); write(io, x); String(take!(io)))
    function m(io::IO, args...)
        print(io, "m(")
        for (i,arg) in enumerate(args)
            JSON3.write(io, arg)
            i != length(args) && print(io, ", ")
        end
        print(io, ')')
    end
    m(args...) = (io = IOBuffer(); m(io, args...); String(take!(io)))
end

import .Mithril

#-----------------------------------------------------------------------------# Node
struct Node
    tag::String
    attrs::Dict{String,String}
    children::Vector
    internal_id::String
    Node(tag, attrs, children) = new(tag, attrs, children, "Node_"*randstring(10))
end
function Base.getproperty(node::Node, class::String)
    node.attrs["class"] = class
    node
end
(node::Node)(children...; kw...) = Node(node.tag, merge(node.attrs, get_attrs(kw)), vcat(node.children, children...))


h(tag, children...; kw...) = Node(tag, get_attrs(kw), collect(children))

function Base.getproperty(::typeof(h), tag::Symbol)
    f(children...; kw...) = h(String(tag), children...; kw...)
    return f
end

get_attrs(kw) = Dict(string(k) => string(v) for (k,v) in kw)

function Base.show(io::IO, M::MIME"text/html", node::Node)
    print(io, "<", node.tag)
    for (k,v) in node.attrs
        if v == "true"
            print(io, ' ', k)
        elseif v == "false"
        else
            print(io, ' ', k, '=', '"', v, '"')
        end
    end
    print(io, '>')
    for child in node.children
        if child isa String
            print(io, child)
        else
            show(io, M, child)
        end
    end
    print(io,"</", node.tag, '>')
end

function Mithril.write(io::IO, node::Node)
    print(io, "m(\"$(node.tag)\"")
    if !isempty(node.attrs)
        print(io, ", ")
        JSON3.write(io, node.attrs)
    end
    if !isempty(node.children)
        print(io, ", ")
        length(node.children) == 1 ? JSON3.write(io, node.children[1]) : JSON3.write(io, node.children)
    end
    print(io, ")")
end




#-----------------------------------------------------------------------------# App
Base.@kwdef mutable struct App
    title::String = "🕸️ Cobweb App"
    layout::Node = h.h1("No ", h.code("layout")."text-gray-800", " has been provided")."text-xl text-center text-red-600"
    state::Config = Config()
    server_functions::Config = Config()  # id => (state,val) -> newstate
    bodyjs::Vector{Node} = Node[]
    asset_directory::String = abspath(joinpath(@__DIR__, "..", "deps"))
end

function get_script(app::App)
    read("action.js", String)
end

function Node(app::App)
    h.html(lang="en",
        h.head(
            h.meta(charset="utf-8"),
            h.meta(name="viewport", content="width=device-width, initial-scale=1"),
            h.title(app.title),
            h.script(src="/assets/tailwindcss.js")
        ),
        h.body(id="root")(
            h.noscript("You need Javascript enabled to run this app."),
            h.script(src="/assets/mithril.js"),
            app.layout,
            h.script(read("main.js"), String)
        )
    )
end

#-----------------------------------------------------------------------------# serve
function serve(app::App, host=Sockets.localhost, port=8080)
    io = IOBuffer()
    println(io, "<!doctype html>")
    show(io, MIME"text/html"(), Node(app))
    index_html = String(take!(io))

    ROUTER = HTTP.Router()
    HTTP.@register(ROUTER, "GET", "/", req -> HTTP.Response(200, index_html))
    HTTP.@register(ROUTER, "GET", "/assets/*", req -> load_asset(app, req))
    # HTTP.@register(ROUTER, "POST", app.endpoint, req -> process_json(app, req))

    @info "Running server on $host:$port..."
    HTTP.serve(ROUTER, host, port)
end

function load_asset(app, req)
    file = HTTP.URIs.splitpath(req.target)[2]
    HTTP.Response(200, read(joinpath(app.asset_directory, file)))
end

end #module
