using Cobweb
using Cobweb: h, Page
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
        CSS(css)
    ),
    h.body(
        h.h1("This page was built with ", h.code("Cobweb.jl"), "."),
        Markdown.parse("""
        Take a look at [`docs/make.jl`](https://github.com/joshday/Cobweb.jl/blob/main/docs/make.jl) inside the [`Cobweb.jl` repo](https://github.com/joshday/Cobweb.jl).
        """)

    )
)

Cobweb.write_html(Page(page))

cp(Cobweb.htmlfile, joinpath(mkpath(joinpath(@__DIR__, "build")), "index.html"), force=true)
