struct Button <: Component
    f::Function
    node::Node
    state::String
    id::String
    Button(f, node::Node, state::String) = new(f, node, state, randstring(20))
    Button(f, state::String, node::Node) = new(f, node, state, randstring(20))
end

function Node(o::Button)
    onClick = AsIs("() => this.action(\"$(o.id)\")")
    h.button(o.node; type="button", onClick, class="bg-$(primary[])-500 hover:bg-$(primary[])-700 text-white font-bold py-2 px-4 rounded")
end
