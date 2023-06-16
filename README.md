[![CI](https://github.com/joshday/Cobweb.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/joshday/Cobweb.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/joshday/Cobweb.jl/branch/main/graph/badge.svg?token=yrcRI2ZETk)](https://codecov.io/gh/joshday/Cobweb.jl)

<h1 align="center">🕸️ Cobweb</h1>

<p align="center">A Julia package for <i>cob</i>bling together <i>web</i> pages.</p>

# Features

- Open any `"text/html"`-representable object in your browser with `Page(x)` or `Tab(x)`.
- Nice syntax for writing HTML: `Cobweb.h.<tag>(children...; attributes...)`.
    - `Cobweb.h.<TAB>` autocompletes HTML5 tags for you.
- Great for templating/building your own `text/html` representations of Julia objects.

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

- `h(tag::String)` creates a `Cobweb.Node`
- `h.<tag>` is simplified syntax for `h(tag)` and you can tab-autocomplete HTML5 tags.

```julia
julia> node = Cobweb.h.div
# <div></div>
```

- Calling a `Node` creates a copy with the specified changes.
    - Positional arguments add *children*:
    ```julia
    julia> node = node("child")
    # <div>child</div>
    ```
    - Keyword arguments add *attributes*:
    ```julia
    julia> node = node(; id = "myid", class="myclass")
    # <div id="myid"></div>
    ```

- There's convenient syntax for appending classes as well:
```julia
julia> node = node."append classes"
# <div id="myid" class="myclass append classes">child</div>
```


### Attributes

- `Node`s act like a mutable NamedTuple when it comes to attributes:
```julia
node = Cobweb.h.div

node.id = "my_id"

node
# <div id="my_id"></div>
```


### Children

- `Node`s act like a `Vector` when it comes to children:

```julia
node = Cobweb.h.div

push!(node, Cobweb.h.h1("Hello!"))

node[:]
# 1-element Vector{Any}:
#  <h1>Hello!</h1>
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


## 📄 Writing Javascript with `Cobweb.Javascript`

- Simple wrapper around a `String` that gets printed verbatim with `MIME"text/javascript"`.
- The following create the same result when represented with `MIME"text/html"`:
    - `h.script("alert('hi')")`
    - `Cobweb.Javascript("alert('hi')")`

<br>
<br>

## 📄 Writing CSS with `Cobweb.CSS`

You can create `Cobweb.CSS` from any nested `AbstractDict`, e.g. `selector => (property => value)`.
- We like using [`EasyConfig.Config`](https://github.com/joshday/EasyConfig.jl) to simplify the syntax.

```julia
using EasyConfig
using Cobweb: h

style = Config()
style.p."font-family" = "Arial"
style."p.upper"."text-transform" = "uppercase"
style."p.blue".color = "blue"

css = Cobweb.CSS(style)
# p {
#   font-family: Arial;
# }
# p.upper {
#   text-transform: uppercase;
# }
# p.blue {
#   color: blue;
# }

page = h.html(
    h.head(css),
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
