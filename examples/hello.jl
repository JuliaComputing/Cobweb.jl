using Cobweb: App, State, serve, Button, h

app = App()

app.state.x = 1

#-----------------------------------------------------------------------------# layout
hello = h.h1."text-xl text-center my-8"("Hello!")

text_with_state = h.p."text-center"(
    "My app has state!  It's ", h.span."text-bold text-2xl"(State("x"))
)

btn = h.div(Button(h.span("Click Me"), "x") do state, val
    state.x += 1
end)."text-center my-8"

app.layout = h.div(hello, text_with_state, btn)

serve(app)
