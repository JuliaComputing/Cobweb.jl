using Cobweb
using Cobweb: h, Page, Node
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
    @test node.attrs["class"] == "class"
    @test length(node.children) == 2
    @test n1 == n2
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
        @test char ∉ Cobweb.escape_html(join(chars))
    end
    @test Cobweb.escape_html("&") != "&"
end
#-----------------------------------------------------------------------------# docs
@testset "Docs Build" begin
    include(joinpath(@__DIR__, "..", "docs", "make.jl"))
    @test isfile(joinpath(@__DIR__, "..", "docs", "build", "index.html"))
    rm(joinpath(@__DIR__, "..", "docs", "build"), recursive=true)
end
