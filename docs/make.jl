using Cobweb
using Cobweb: h, Page, CSS
using Markdown

css = Dict(
    "html" => Dict(
        "font-family" => "Arial"
    )
)

page = h.html(
    h.head(
        h.meta(charset="UTF-8"),
        h.meta(name="viewport", content="width=device-width, initial-scale=1.0"),
        h.title("Cobweb.jl Docs"),
        CSS(css),
    ),
    h.body(
        h.h1("This page was built with ", h.code("Cobweb.jl"), "."),
        Markdown.parse("""
        Take a look at [`docs/make.jl`](https://github.com/joshday/Cobweb.jl/blob/main/docs/make.jl) inside the [`Cobweb.jl` repo](https://github.com/joshday/Cobweb.jl).
        """),
        h.button("Click Me for an alert!", onclick="buttonClicked()"),
        Cobweb.Javascript("const buttonClicked = () => alert('This button was clicked!')"),
    )
)

index_html = touch(joinpath(mkpath(joinpath(@__DIR__, "build")), "index.html"))

Cobweb.save(Page(page, "build"), index_html)
