module Cobweb

using JSON3
using EasyConfig
using HTTP
using Sockets

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
    endpoint::String = "/internal_api"
    bodyjs::Vector{Node} = Node[]
    asset_directory::String = abspath(joinpath(@__DIR__, "..", "deps"))
end


function Node(app::App)
    h.html(lang="en",
        h.head(
            h.meta(charset="ut7-8"),
            h.meta(name="viewport", content="width=device-width, initial-scale=1"),
            h.title(app.title)
        ),
        h.body(id="root")(
            h.noscript("You need Javascript enabled to run this app."),
            h.script(src="/assets/mithril.js"),
            app.layout
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

# export node

# primary = Ref("indigo")
# secondary = Ref("orange")

# #-----------------------------------------------------------------------------# utils
# abstract type Component end
# Base.show(io::IO, c::Component) = show(io, Node(c))

# struct State
#     x::String
# end
# StructTypes.StructType(::Type{State}) = StructTypes.StringType()
# Base.show(io::IO, o::State) = print(io, "this.state.$(o.x)")
# JSON3.write(s::State) = string(s)

# struct AsIs
#     x::String
# end
# Base.show(io::IO, o::AsIs) = print(io, o.x)
# JSON3.write(s::AsIs) = string(s)

# #-----------------------------------------------------------------------------# Fields
# struct Fields{T}
#     item::T
# end
# Base.getproperty(fields::Fields, x::Symbol) = getfield(getfield(fields, :item), x)
# Base.getproperty(fields::Fields, x) = getproperty(fields, Symbol(x))
# Base.setproperty!(fields::Fields, prop::Symbol, x) = setfield!(getfield(fields, :item), prop, x)
# Base.setproperty!(fields::Fields, prop, x) = setfield!(getfield(fields, :item), Symbol(prop), x)

# #-----------------------------------------------------------------------------# Node
# struct Node
#     type::String
#     attrs::Dict{String,Any}
#     children::Vector
# end

# function (node::Node)(args...; kw...)
#     o = Fields(node)
#     d2 = Dict{String,Any}(string(k) => v for (k,v) in kw)
#     Node(o.type, merge(o.attrs, d2), vcat(o.children, args...))
# end

# h(type, children...; kw...) = Node(type, Dict{String,Any}(string(k) => v for (k,v) in kw), collect(children))

# Base.getproperty(::typeof(h), x::Symbol) = h(string(x))

# function Base.getproperty(node::Node, x::String)
#     Fields(node).attrs["class"] = x
#     node
# end

# # Turn into Preact.h() / Preact.createElement() call
# function Base.show(io::IO, node::Node; color=0, indent="")
#     o = Fields(node)
#     p(args...) = printstyled(io, args...; color)
#     p("h('", node.type, "', ")
#     if isempty(o.attrs)
#         p("null")
#     else
#         p("{ ")
#         for (i, (k,v)) in enumerate(o.attrs)
#             p(k, ": ", JSON3.write(v))
#             i != length(o.attrs) && p(", ")
#         end
#         p(" }")
#     end
#     haschildnodes = any(x -> x isa Node, o.children)
#     for (i, child) in enumerate(o.children)
#         c = color + i
#         p(", ")
#         haschildnodes && p('\n', indent * "    ")
#         if child isa Node
#             show(io, child, color=c, indent = indent * "    ")
#         elseif child isa Component
#             show(io, Node(child), color=c, indent = indent * "    ")
#         else
#             p(JSON3.write(child))
#         end
#     end
#     haschildnodes && p('\n', indent)
#     p(')')
# end
# function Base.show(io::IO, M::MIME"text/html", node::Node)
#     o = Fields(node)
#     print(io, "<$(o.type)")
#     for (k,v) in o.attrs
#         print(io, " $k=", JSON3.write(v))
#     end
#     print(io, ">")
#     for child in o.children
#         if child isa Node
#             show(io, M, child)
#         else
#             print(io, child)
#         end
#     end
#     println(io, "</$(o.type)>")
# end

# #-----------------------------------------------------------------------------# App
# Base.@kwdef mutable struct App
#     title::String = "🕸️ Cobweb App"
#     layout::Node = h.h1("No ", h.code("layout")."text-gray-800", " has been provided")."text-xl text-center text-red-600"
#     state::Config = Config()
#     server_functions::Config = Config()  # id => (state,val) -> newstate
#     endpoint::String = "/internal_api"
#     assets::Vector{Node} = Node[]
# end
# function Base.show(io::IO, app::App)
#     println(io, "App: \"$(app.title)\"")
#     println(io, "  • endpoint: ", app.endpoint)
#     println(io, "  • Initial state:")
#     JSON3.write(io, app.state)
#     println(io, "\n  • layout:")
#     show(io, app.layout)
# end

# function Base.setproperty!(app::App, name::Symbol, x)
#     setfield!(app, name ,x)
#     if name === :layout
#         app.server_functions = get_server_functions(app.layout)
#     end
# end

# function get_server_functions(node::Node)
#     c = Config()
#     for child in Fields(node).children
#         if child isa Component
#             c[child.id] = child.f
#         elseif child isa Node
#             merge!(c, get_server_functions(child))
#         end
#     end
#     return c
# end

# function Node(o::App)
#     h.html(lang="en",
#         h.head(
#             h.title(o.title),
#             h.meta(name="viewport", content="width=device-width, initial-scale=1.0"),
#             h.meta(charset="utf-8"),
#             h.script(src="/assets/tailwindcss.js"),
#             h.script(src="/assets/preact.min.js"),
#             o.assets...,
#             h.script(type="module", indexjs(o))
#         ),
#         h.body("Loading...")  # Gets overwritten by script
#     )
# end

# #-----------------------------------------------------------------------------# indexjs
# function indexjs(app::App)
#     io = IOBuffer()
#     show(io, app.layout)
#     layout = String(take!(io))
#     """
#         import { html, h, Component, render } from 'https://unpkg.com/htm/preact/index.mjs?module'

#         class App extends Component {
#             state = $(JSON3.write(app.state))

#             action (component_id, value=null, keys=null) {
#                 const state = JSON.parse(JSON.stringify(this.state));  // TODO: only use provided keys
#                 console.log(`Sending state: \${JSON.stringify(state)}.`)

#                 state.__COMPONENT_ID__ = component_id;
#                 state.__COMPONENT_VALUE__ = value;
#                 fetch("$(app.endpoint)", {
#                     method: 'POST',
#                     headers: {'Content-Type': 'application/json'},
#                     body: JSON.stringify(state)
#                 })
#                 .then(response => response.json())
#                 .then(data => {
#                     console.log(`From Julia: \${JSON.stringify(data)}`)
#                     this.setState(s => ({...s, ...data}))
#                 })
#                 .then(() => console.log(`State Update: \${JSON.stringify(this.state)}`))
#             };

#             componentDidMount() {
#                 console.log(`Initial state: \${JSON.stringify(this.state)}`)
#                 this.action("__INITIALIZE_STATE__", null)
#             };

#             componentWillUpdate() {
#                 $(app.componentWillUpdate)
#             }

#             render() {
#                 return $(app.layout)
#             }
#         }

#         document.body.innerHTML = \"\"; // Remove "Loading..." from page.

#         render(html`<\${App} />`, document.body);
#     """
# end

# #-----------------------------------------------------------------------------# process_json
# function process_json(app::App, req::HTTP.Request)
#     json = JSON3.read(req.body, Config)

#     # debugging
#     io = IOBuffer()
#     JSON3.pretty(io, json)
#     printstyled("process_json called with data:\n", color=:light_cyan)
#     printstyled(String(take!(io)); color=:light_green)
#     println(); println()

#     id = json.__COMPONENT_ID__
#     val = json.__COMPONENT_VALUE__
#     if id == "__INITIALIZE_STATE__"
#         @info "Intializing state..."
#         return HTTP.Response(200, ["Content-Type"=>"application/json"]; body=JSON3.write(app.state))
#     else
#         app.server_functions[id](json, val)
#     end
#     delete!(json, :__COMPONENT_ID__)
#     delete!(json, :__COMPONENT_VALUE__)
#     @info "Returning:" JSON3.write(json)
#     return HTTP.Response(200,  ["Content-Type"=>"application/json"]; body=JSON3.write(json))
# end



# #-----------------------------------------------------------------------------# components
# include("components.jl")

end #module
