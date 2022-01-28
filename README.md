# Cobweb

A Julia package for **cob**bling together **web** pages.

# Cool Features

- Instantly open any `"text/html"`-representable object inside your browser with `Cobweb.Page(x)`
- Easily create web content with `Cobweb.h(tag, content...; attrs)`

# Creating Nodes with `Cobweb.h`

- The syntax for `Cobweb.h` is designed to look similar to html:

```julia
using Cobweb: h
using Markdown

h.div()."text-center text-xl"(
    h.h4("This generates an h2 node"; class="you_can_add_classes_this_way_too", id="or_any_other_attribute"),
    h.p("This is a paragraph."),
    h.div(Markdown.parse("- I can put any text/html-representable type in here! and will \"just work\"™"))
)
```

- This creates (take a look at the raw README.md file to see the html):

<div class="text-center text-xl"><h4 class="you_can_add_classes_this_way_too" id="or_any_other_attribute">This generates an h2 node</h4><p>This is a paragraph.</p><div><div class="markdown"><ul>
<li><p>I can put any text/html-representable type in here&#33; and will &quot;just work&quot;™</p>
</li>
</ul>
</div></div></div>


## Attributes

- Only `Bool` is special-cased:
    - `h.div(hidden=true)` --> `<div hidden></div>`
    - `h.div(hidden=false)` --> `<div></div>`
- Everything else is converted to `String`.

## Writing HTML

- A `Cobweb.Node` displays in the REPL as HTML.  This is the same representation that gets used by:

```julia
Base.show(::IO, ::MIME"text/html", ::Node)
```

## Writing Javascript

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

### Generated HTML:

```html
<html>
  <head>
    <meta charset="UTF-8"></meta>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"></meta>
    <title>Page Title</title>
  </head>
  <body>
    <h1>This is my page title.</h1>
    <p>This is a paragraph.</p>
  </body>
</html>
```
