using Cobweb: App, h, serve

app = App()

btn = Button("Click Me")

btn_result = h.div()."text-gray-300 my-8"

callback!(btn) do state, val
    InnerHTML(btn_result, "The button has been clicked $(state.nclicks) times.")
end

app.layout = h.div(class="text-center")(
    h.h1("This is my app!", class="text-2xl text-gray-800 my-8"),
    h.p("This is a paragraph.", class="text-gray-500 my-8"),
    btn,
    btn_result
)

serve(app)
