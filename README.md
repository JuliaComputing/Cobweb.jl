[![CI](https://github.com/joshday/Cobweb.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/joshday/Cobweb.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/joshday/Cobweb.jl/branch/main/graph/badge.svg?token=yrcRI2ZETk)](https://codecov.io/gh/joshday/Cobweb.jl)

<h1 align="center">🕸️ Cobweb</h1>

<h4 align="center">A Julia package for <b>cob</b>bling together <b>web</b> pages.</h4>

# 🆒 Features

- Open any `"text/html"`-representable object in your browser with `Cobweb.Page(x)`.
- Easily create web content in Julia.
- Lightweight, simple, and hackable.

<br><br>

## 🚀 Quickstart

```julia
using Cobweb: h, Page

page = h.html(
    h.head(
        h.meta(charset="UTF-8"),
        h.meta(name="viewport", content="width=device-width, initial-scale=1.0"),
        h.title("Page Title")
    ),
    h.body(
        h.h1("This is my page title."),
        h.p("This is a paragraph."),
        h.button("Click Me for an alert!", onclick="buttonClicked()"),
        Cobweb.Javascript("const buttonClicked = () => alert('This button was clicked!')"),
    )
)

Page(page)  # Open in browser
```

<br>
<br>

# ✨ Creating Nodes with `Cobweb.h`

- Syntax is similar to HTML:

```julia
using Cobweb: h

h.div."some-class"(
    h.p("This is a child."),
    h.div("So is this.")
)
# <div class="some-class">
#   <p>This is a child.</p>
#   <div>So is this.</div>
# </div>
```

- Any `Union{AbstractString, Symbol, Number}` children will be inserted verbatim.
- Everything else will use the `MIME"text/html"` representation.

```julia
using Markdown

h.div(
    "Here is markdown:",
    Markdown.parse("""
    - This \"just work\"™s!
    """)
)
# <div>
#   Here is markdown:
#   <div class="markdown">
#     <ul>
#       <li>
#         <p>This &quot;just work&quot;™s&#33;</p>
#       </li>
#     </ul>
#   </div>
# </div>
```


<br>
<br>

## `Cobweb.h` Syntax Summary:

- `h.<tag>` creates a `Cobweb.Node`:

```julia
julia> h.div
# <div></div>
```

- `Node`s are callable!
    - Positional arguments add children:
    ```julia
    julia> h.div("child")
    # <div>child</div>
    ```
    - Keyword arguments add attributes:
    ```julia
    julia> node = h.div(; id = "myid", class="myclass")
    # <div id="myid"></div>
    ```

- There's convenient syntax for appending classes as well:
```julia
julia> node."append classes"
# <div class="myclass append classes" id="myid"></div>
```


- `Bool`s are special-cased:

```julia
julia> h.div(hidden=true)
# <div hidden></div>

julia> h.div(hidden=false)
# <div></div>
```

<br>
<br>

## The `@h` macro

This is a simple utility macro that replaces each HTML5 tag `x` with `Cobweb.h.x` for a cleaner syntax:

```julia
Cobweb.@h begin
    div."text-center text-xl"(
        h4("This generates an h4 node!"),
        p("This is a paragraph"),
        div("Here is a div.")
    )
end
# <div class="text-center text-xl">
#   <h4>This generates an h4 node!</h4>
#   <p>This is a paragraph</p>
#   <div>Here is a div.</div>
# </div>
```

<br>
<br>

## Using Cobweb.jl with [Pluto.jl](https://github.com/fonsp/Pluto.jl)

- Use `Cobweb.iframe(x)` to sandbox (escape Pluto's CSS and JS) your content.
- Rather than using a `src` attribute to embed a page (as with `h.iframe(src="myurl.html")`), the
  html representation of `x` is used.

![](https://user-images.githubusercontent.com/8075494/208716692-7c5afc5c-ad51-40ea-9f54-7767cb2ac082.png)

<br>
<br>


## 📄 Writing Javascript with `Cobweb.Javascript`

- Simple wrapper around a `String` that gets printed verbatim with `MIME"text/javascript"`.
- The following create the same result when represented with `MIME"text/html"`:
    - `h.script("alert('hi')")`
    - `Cobweb.Javascript("alert('hi')")`

<br>
<br>

## 📄 Writing CSS with `Cobweb.CSS`

You can create `Cobweb.CSS` from any `AbstractDict`:
- `selector => AbstractDict (property => value)`.
- We like using [`EasyConfig.Config`](https://github.com/joshday/EasyConfig.jl) for this.

```julia
using EasyConfig
using Cobweb: h

css = Config()

css."p"."font-family" = "Arial"
css."p.upper"."text-transform"= "uppercase"
css."p.blue".color = "blue"


# p {
#     font-family: Arial;
# }
# p.upper {
#     text-transform: uppercase;
# }
# p.blue {
#     color: blue;
# }

page = h.html(
    h.head(Cobweb.CSS(css)),
    h.body(
        h.p("this is uppercased and blue in an Arial font.", class="upper blue")
    )
)

Cobweb.Page(page)
```


<br>
<br>

## Parsing HTML to `Cobweb.Node`

```julia
using Downloads, Cobweb

Cobweb.read(Downloads.download("https://juliacomputing.github.io/Cobweb.jl/"))
```

<br>
<br>

## Attribution

- Cobweb.jl is highly influenced by [Hyperscript.jl](https://github.com/JuliaWeb/Hyperscript.jl)
