using Cobweb
using Cobweb: h, Page, Node, attrs, tag, children
using Test

n1 = h.div("hi")
n2 = h(:div, "hi")

#-----------------------------------------------------------------------------# Creating Nodes
@testset "Node Creation" begin
    for node in [
            h(:div),
            h.div(),
            h(:div, "child"),
            h.div("child"),
            h.(:p, "c1", "c2"),
            h.p("c1", "c2"),
            h.h1()."class"("c1", "c2")
        ]
        @test node isa Node
    end
    node = h.h1()."class"("c1", "c2")
    @test attrs(node)[:class] == "class"
    @test length(children(node)) == 2
    @test n1 == n2

    # _h
    @test Cobweb._h(:(div("hi"))) == :(Cobweb.h.div("hi"))
    @test Cobweb.@h div(b(), hr(), p("text")) == h.div(h.b(), h.hr(), h.p("text"))

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
#-----------------------------------------------------------------------------# HTML
@testset "HTML" begin
    @test repr(n1) == "<div>hi</div>"
end
#-----------------------------------------------------------------------------# Javascript
@testset "Javascript" begin
    @test repr("text/javascript", Cobweb.Javascript("x")) == "x"
    @test repr("text/html", Cobweb.Javascript("x")) == "<script>x</script>"
end
#-----------------------------------------------------------------------------# CSS
@testset "CSS" begin
    @test repr("text/css", Cobweb.CSS("x")) == "x"
    @test repr("text/html", Cobweb.CSS("x")) == "<style>x</style>"
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
        open(io -> write(io, node), file, "w")
        node2 = Cobweb.read(file)[end]
        @test node == node2
    end
end
#-----------------------------------------------------------------------------# IFrame
@testset "IFrame" begin
    o = IFrame("test", height="100px")
    @test occursin("100px", repr("text/html", o))
end
#-----------------------------------------------------------------------------# pretty
@testset "pretty" begin
    @test Cobweb.pretty(h.div(h.p("A"), h.p("B"))) == "<div>\n    <p>A</p>\n    <p>B</p>\n</div>"
end

#-----------------------------------------------------------------------------# other
@testset "other" begin
    @test repr("text/html", Cobweb.Doctype()) == "<!DOCTYPE html>"
    @test repr("text/html", Cobweb.Comment("text")) == "<!-- text -->"
end
