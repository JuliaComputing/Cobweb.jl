# Cobweb

A Julia package for **cob**bling together **web** pages.

# `h`

- You create nodes with the `h` function:

```julia
h(tag, content...; attrs...)
```

- The following create the same node:

```julia
using Cobweb: h

h("div", "content", class="class1 class2", id="my_id")

h.div("content"; class="class1 class2", id="my_id")

h.div(class="class1 class2", id="my_id")("content")

h.div(id="my_id")."class1 class2"("content")
```

## Attributes

- Only `Bool` is special-cased as an attribute:
    - `h.div(hidden=true)` --> `<div hidden></div>`
    - `h.div(hidden=false)` --> `<div></div>`
- Everything else is converted to `String`.

## HTML

- A `Cobweb.Node` displays in the REPL as HTML.  This is the same representation that gets used by:

```julia
Base.show(::IO, ::MIME"text/html", ::Node)
```

## Javascript

- `Cobweb.Node`s can be represented as a Javascript object that many libraries use internally to
represent nodes ([React.js](https://reactjs.org), [Preact.js](https://preactjs.com), [Mithril.js](https://mithril.js.org)):

```javascript
{tag, attrs, child1, child2, ...}
```

- Example (e.g. for React, you'd need `const m = React.createElement;` in your script.)

```julia
using Cobweb: h

node = h.div(h.p("paragraph 1"), h.p("paragraph 2"), class="text-center")

print(repr("text/javascript", node))
# m("div", {class:"text-center"}, m("p", null, "paragraph 1"), m("p", null, "paragraph 2"))
```


## Full Page example

```
using Cobweb: h

page = h.html(
    h.head(
        h.meta(charset="UTF-8"),
        h.meta(name="viewport", content="width=device-width, initial-scale=1.0"),
        h.title("Page Title")
    ),
    h.body(
        h.h1("This is my page title."),
        h.p("This is a paragraph.)
    )
)
```
