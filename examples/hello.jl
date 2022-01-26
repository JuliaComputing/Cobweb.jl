using Cobweb: App, h, serve

app = App()

app.layout = h.div(class="text-centered")(
    h.h1("This is my app!"),
    h.p("This is a paragraph.")
)

serve(app)
