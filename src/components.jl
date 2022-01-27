abstract type Component end
# init_state(::Component)
# interact(::Component, state, [val])

#-----------------------------------------------------------------------------# callbacks
# f is a function of Component's current state and
function callback!(f, o::Component)
    o.callback = f
    o.callback(init_state(o), init_val(o))
end

# Callbacks must return one of the following
struct InnerHTML
    target_internal_id::String
    html::String
end

#-----------------------------------------------------------------------------# Button
mutable struct Button <: Component
    label::String
    internal_id::String
    callback::Union{Function,Nothing}
end
init_state(b::Button) = Config(nclicks = 0)
init_val(b::Button) = nothing

interact(::Button, state) = (state.nclicks += 1)

function handler(o::Button)

end



#-----------------------------------------------------------------------------# Dropdown
struct Dropdown <: Component
    label::String
    options::String
end
state(b::Button) = Config(selected="")
interact(::Dropdown, state, val) = (state.selected = val)
