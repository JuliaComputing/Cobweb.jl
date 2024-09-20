using Cobweb
using Cobweb: h, CSS
using Markdown

page = h.html(
    h.head(
        h.meta(charset="UTF-8"),
        h.meta(name="viewport", content="width=device-width, initial-scale=1.0"),
        h.title("Cobweb.jl Docs"),
        CSS("""
        html {
            font-family: Arial;
        }
        """)
    ),
    h.body(
        h.h1("This page was built with ", h.code("Cobweb.jl"), "."),
        md"""
        Take a look at [`docs/make.jl`](https://github.com/joshday/Cobweb.jl/blob/main/docs/make.jl) inside the [`Cobweb.jl` repo](https://github.com/joshday/Cobweb.jl).
        """,
        h.button("Click Me for an alert!", onclick="buttonClicked()"),
        Cobweb.Javascript("const buttonClicked = () => alert('This button was clicked!')"),
    )
)

index_html = touch(joinpath(mkpath(joinpath(@__DIR__, "build")), "index.html"))

open(index_html, "w") do io
    println(io, Cobweb.Doctype())
    write(io, page)
end
