[![CI](https://github.com/JuliaComputing/Cobweb.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaComputing/Cobweb.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/JuliaComputing/Cobweb.jl/branch/main/graph/badge.svg?token=yrcRI2ZETk)](https://codecov.io/gh/JuliaComputing/Cobweb.jl)

<h1 align="center">🕸️ Cobweb</h1>

<p align="center">A Julia package for <i>cob</i>bling together <i>web</i> pages.</p>

# Features

- Open `"text/html"`-representable objects in your browser with `preview(x)`.
- Clean syntax for writing HTML: `h.<tag>(children...; attrs...)`

```julia
h.div(class="myclass", style="color:red;")("content!")
# <div class="myclass" style="color:red;">content!</div>
```

<br><br>

## 🚀 Quickstart

```julia
using Cobweb: h, preview

body = h.body(
    h.h1("Here is a title!"),
    h.p("This is a paragraph."),
    h.button("Click Me for an alert!", onclick="buttonClicked()"),
    h.script("const buttonClicked = () => alert('This button was clicked!')"),
)

preview(body)
```

<br>
<br>

# ✨ Writing HTML with `Cobweb.h`

### `h` is a pretty special function

```julia
h(tag::Symbol, children...; attrs...)

# The dot syntax (getproperty) lets you autocomplete HTML5 tags
h.tag # == h(:tag)
```

### `h` Creates a `Cobweb.Node`

- `Cobweb.Node`s are callable (creates a copy with new children/attributes):

```julia
h.div("hi")  # positional arguments add *children*

h.div(style="border:none;")  # keyword arguments add *attributes*

# These all produce the same result:
h.div("hi"; style="border:none;")
h.div(style="border:none;", "hi")
h.div(style="border:none;")("hi")
h.div("hi")(style="border:none;")
```

### Child Elements can be Anything

- If a `child` isn't `MIME"text/html"`-representable, it will be added as a `HTML(child)`.
- Note: `HTML(x)` means "insert this into HTML as `print(x)`".

```julia
# e.g. Strings have no text/html representation, so the added child is `HTML("hi")`
h.div("hi")
# <div>hi</div>

# You can take advantage of Julia structs that already have text/html representations:
using Markdown

md_example = h.div(md"""
# Here is Some Markdown

- This is easier than writing html by hand.
- And it "just works".
""")

preview(md_example)
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
node = Cobweb.h.div  # <div></div>

push!(node, Cobweb.h.h1("Hello!"))

node  # <div><h1>Hello!</h1></div>

node[1] = "changed"

node  # <div>changed</div>

collect(node)  # ["changed"]
```

<br>
<br>

## The `@h` macro

This is a simple utility macro that replaces each HTML5 tag `x` with `Cobweb.h.x` for a cleaner syntax:

```julia
Cobweb.@h begin
    div(class="text-center text-xl",
        h4("This generates an h4 node!"),
        p("This is a paragraph"),
        div("Here is a div.")
    )
end
```

<br>
<br>

## 📄 Writing Javascript and CSS

- Cobweb exports `Javascript` and `CSS` string wrappers that `show` appropriately in different mime types:
- You can also construct these wrappers with `js"..."` and `css"..."`.

```julia
Javascript("alert('hello')")
# text/javascript   --> `alert('hello')`
# text/html         --> `<script>alert('hello')</script>`

CSS("""html { border: none; }""")
# text/css          --> `html { border: none; }`
# text/html         --> `<style>html { border: none; }</style>`
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

- Cobweb.jl is influenced by [Hyperscript.jl](https://github.com/JuliaWeb/Hyperscript.jl)
