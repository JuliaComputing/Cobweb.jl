### A Pluto.jl notebook ###
# v0.19.9

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

# ╔═╡ c9a11198-bcaf-4809-b0f7-5f96a45c18d5
Cobweb.iframe("hi", height=50)

# ╔═╡ Cell order:
# ╠═4dc9c790-8080-11ed-10a2-a569a7b2a594
# ╠═eb297515-7bf4-452e-bdb9-24cbbbe69d55
# ╠═c9a11198-bcaf-4809-b0f7-5f96a45c18d5
