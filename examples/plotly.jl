using Cobweb: App, State, serve, Button, h, AsIs
using PlotlyLight

app = App()

push!(app.assets, h.script(src="https://cdn.plot.ly/plotly-latest.min.js"))

app.state.data = Config(x=randn(1), y=randn(1))

app.layout = h.div(
    h.div(id="plot_div"),
    # AsIs("html`$(repr("text/html", Plot()))`"),
    # h.script("Plotly.newPlot('plot_div', [this.state.data])"),
    Button(h.span("Click to add data"), "unused") do state, val
        push!(state.data.x, randn())
        push!(state.data.y, randn())
    end
)

serve(app)
