# Cobweb

A Julia package for **cob**bling together **web** pages.

# Creating Nodes with `Cobweb.h`

- You create nodes with the `h` function:

```julia
h(tag, content...; attrs...)
```

- The following lines all create the same node:

```julia
using Cobweb: h

h("div", "content", class="class1 class2", id="my_id")

h.div("content"; class="class1 class2", id="my_id")

h.div(class="class1 class2", id="my_id")("content")

h.div(id="my_id")."class1 class2"("content")
```

- In other words:
- `h.p(args...; kw...)` is the same as `h("p", args...; kw...)`
- `mydiv."c1 c2"` "overwrites" the `class` attribute with `"c1 c2"`
    - Nothing is actually overwritten, but another `Node` is generated.

## Attributes

- Only `Bool` is special-cased:
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
represent nodes (e.g. [React.js](https://reactjs.org), [Preact.js](https://preactjs.com), and [Mithril.js](https://mithril.js.org)):

```javascript
{tag, attrs, child1, child2, ...}
```

- Example

```julia
using Cobweb: h

node = h.div(h.p("paragraph 1"), h.p("paragraph 2"), class="text-center")

print(repr("text/javascript", node))
# m("div", {class:"text-center"}, m("p", null, "paragraph 1"), m("p", null, "paragraph 2"))
```

- If you were writing this node into a React script for example, you'd want it to look something like:

```javascript
const m = React.createElement

const app = ... // repr("text/javascript", node)

ReactDOM.render(app, document.getElementById('root'));
```


## Full Page example

- For working interactively, you can repeatedly call `Cobweb.Page(mynode)` to open up a browser window/tab

```
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

Page(page)
```
