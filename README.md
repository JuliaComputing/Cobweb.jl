<h1 align="center">🕸️ Cobweb</h1>

<h4 align="center">A Julia package for <b>cob</b>bling together <b>web</b> pages.</h4>

# 🆒 Features

- Instantly open any `"text/html"`-representable object inside your browser with `Cobweb.Page(x)`.
- Easily create web content with `Cobweb.h(tag, content...; attrs...)`.
- Small and hackable (~200 lines).
- Take advantage of Julia types that have a `MIME("text/html")` representation.

<br>
<br>

# ✨ Creating Nodes with `Cobweb.h`

- The syntax for `Cobweb.h` is designed to look similar to html.

```julia
using Cobweb: h
using Markdown

h.div()."text-center text-xl"(
    h.h3("This generates an h3 node!"; class="you_can_add_classes_this_way_too", id="or_any_other_attribute"),
    h.p("This is a paragraph."),
    h.div(Markdown.parse("- I can put any text/html-representable type in here! and will \"just work\"™"))
)
```

<div class="text-center text-xl"><h3 class="you_can_add_classes_this_way_too" id="or_any_other_attribute">This generates an h3 node!</h3><p>This is a paragraph.</p><div><div class="markdown"><ul>
<li><p>I can put any text/html-representable type in here&#33; and will &quot;just work&quot;™</p>
</li>
</ul>
</div></div></div>

### `Cobweb.h` Syntax Summary:

- `node = h(tag, children...; attrs...)`
- `node = h.tag(children...; attrs...)`
- `node."add_class"`
- `node("add", "children")`
- `node.attrs["some_attribute"] = "add an attribute"`
- `Bool` attributes are special cased:
    - `h.div(hidden=true)` --> `<div hidden></div>`
    - `h.div(hidden=false)` --> `<div></div>`

<br>
<br>

## The `@h` macro

This is a simple utility macro that replaces symbols `f` with `Cobweb.h.f` for a cleaner syntax:

```julia
Cobweb.@h begin
    div()."text-center text-xl"(
        h4("This generates an h4 node!"),
        p("This is a paragraph"),
        div("Here is a div.")
    )
end
```


<br>
<br>

## 📄 Writing HTML

- A `Cobweb.Node` (what gets created by `Cobweb.h`) displays in the REPL as HTML.  This is the same representation that gets used by: `Base.show(::IO, ::MIME"text/html", ::Node)`.  You can add whitespace/indentation with `Cobweb.pretty(::IO, ::Node)`.

<br>
<br>


## 📄 Writing Javascript with `Cobweb.Javascript`

- Simple wrapper around a `String` that gets printed verbatim with `MIME"text/javascript"`.
- The following create the same result represented with `MIME"text/html"`:
    - `h.script("alert('hi')")`
    - Adding `Cobweb.Javascript("alert('hi')")`

<br>
<br>

## CSS

You can create `Cobweb.CSS` from any `AbstractDict`:
- `selector => AbstractDict (property => value)`.
- We like using [`EasyConfig.Config`](https://github.com/joshday/EasyConfig.jl) for this.
- `Cobweb.CSS` can be included directly (because of its `MIME("text/html")` show method).  You can
  also write to a file with `open(io -> show(io, css), mycssfile)`.

```julia
using EasyConfig
using Cobweb: h

css = Config()

css.p."font-family" = "Arial"
css."p.upper"."text-transform"= "uppercase"
css."p.blue".color = "blue"

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

## 🏃 Quickstart

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
        h.p("This is a paragraph.")
    )
)

Page(page)  # Open in browser
```

## Attribution

- Cobweb.jl is highly influenced by [Hyperscript.jl](https://github.com/JuliaWeb/Hyperscript.jl)
