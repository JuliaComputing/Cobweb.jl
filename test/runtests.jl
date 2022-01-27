using Cobweb
using Cobweb: h
using Test

n1 = h.div("hi")

@testset "HTML" begin
    @test repr(n1) == "<div>hi</div>"
end
@testset "Javascript" begin
    @test repr("text/javascript", n1) == """m("div", null, "hi")"""
end
