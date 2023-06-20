using Cobweb
using Cobweb: h, hx, Page, Node, attrs, tag, children
using Test

n1 = h.div("hi")
n2 = h("div", "hi")

#-----------------------------------------------------------------------------# Creating Nodes
@testset "Node Creation" begin
    for node in [
            h("div"),
            h.div(),
            h("div", "child"),
            h.div("child"),
            h.("p", "c1", "c2"),
            h.p("c1", "c2"),
            h.h1()."class"("c1", "c2")
        ]
        @test node isa Node
    end
    node = h.h1()."class"("c1", "c2")
    @test attrs(node)["class"] == "class"
    @test length(children(node)) == 2
    @test n1 == n2

    # edit attributes after creation
    n = h.div("hi")
    n.id = "someid"
    @test n.id == "someid"

    # edit children after creation
    @test only(children(n)) == "hi"
    @test n[1] == "hi"
    @test_throws BoundsError n[2]
    n[1] = "new"
    @test n[1] == "new"
end
#-----------------------------------------------------------------------------# indexing
@testset "get/setindex" begin
    o = h.div("hi")
    @test o[1] == "hi"
    @test only(o) == "hi"
    @test o[:] == ["hi"]
    @test collect(o) == ["hi"]
end
#-----------------------------------------------------------------------------# HTMX
@testset "HTMX" begin
    n = h.div
    nhx = n.hx
    nhx.swap = "innerHTML"
    n.swap = "something else"
    @test nhx.swap == "innerHTML"
    @test n.swap == "something else"
    @test n.hx.swap == "innerHTML"
    @test n.hx.swap == attrs(n)["hx-swap"]
    @test n.swap == attrs(n)["swap"] 
    
    @test hx.target == :target

    nhx(hx.target, "/mytarget")
    @test nhx.target == "/mytarget"
    @test n.hx.target == "/mytarget"
    @test n.hx.target == attrs(n)["hx-target"]


end
#-----------------------------------------------------------------------------# HTML
@testset "HTML" begin
    @test repr(n1) == "<div>hi</div>"
end
#-----------------------------------------------------------------------------# Javascript
@testset "Javascript" begin
    @test repr("text/javascript", Cobweb.Javascript("x")) == "x"
    @test repr("text/html", Cobweb.Javascript("x")) == "<script>x</script>"
end
#-----------------------------------------------------------------------------# Page
@testset "Page" begin
    page = Page(n1)
    @test Page(page) == page
    Cobweb.save(page)
    @test isfile(joinpath(Cobweb.DIR, "index.html"))

    Cobweb.save(page, "temp.html")
    @test isfile("temp.html")
    rm("temp.html", force=true)
end
#-----------------------------------------------------------------------------# escaping
@testset "escaping" begin
    chars = ['<', '>', ''', '"']
    for char in chars
        @test char ∉ Cobweb.escape(join(chars))
    end
    @test Cobweb.escape("&") != "&"
end
#-----------------------------------------------------------------------------# docs
@testset "Docs Build (read/write)" begin
    include(joinpath(@__DIR__, "..", "docs", "make.jl"))
    @test isfile(joinpath(@__DIR__, "..", "docs", "build", "index.html"))

    input = Cobweb.read(joinpath(@__DIR__, "..", "docs", "build", "index.html"))
    @test input[1] == Cobweb.Doctype()

    rm(joinpath(@__DIR__, "..", "docs", "build"), recursive=true)

    @testset "roundtrip" begin
        node = h.div("hi"; class="myclass", id="myid")
        file = tempname()
        Cobweb.save(file, Page(node))
        node2 = Cobweb.read(file)[end]
        @test node == node2
    end
end
#-----------------------------------------------------------------------------# IFrame
@testset "IFrame" begin
    o = IFrame(height="100px")
    @test occursin("100px", repr("text/html", o))
end
