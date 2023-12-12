### A Pluto.jl notebook ###
# v0.19.35

using Markdown
using InteractiveUtils

# ╔═╡ 4dc9c790-8080-11ed-10a2-a569a7b2a594
begin
	using Pkg
	Pkg.activate(joinpath(@__DIR__, ".."))
	using Cobweb: Cobweb, h
	using Random
end

# ╔═╡ eb297515-7bf4-452e-bdb9-24cbbbe69d55
h.div("hi")

# ╔═╡ cb27e1ae-9e18-4575-a134-ad4147a8a151
Cobweb.IFrame(h.div("sup", style="color:red;"), width="100%")

# ╔═╡ Cell order:
# ╠═4dc9c790-8080-11ed-10a2-a569a7b2a594
# ╠═eb297515-7bf4-452e-bdb9-24cbbbe69d55
# ╠═cb27e1ae-9e18-4575-a134-ad4147a8a151
