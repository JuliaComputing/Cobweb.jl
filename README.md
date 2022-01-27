# Cobweb

## Notes

- Interaction with server must be done through a `Component`.
- The script needs to keep track:
    - `nodes`: object of `"node_id": document.getElementById("node_id")`
    - nodes can be created or deleted on any action


## Example Interaction

- Client's POST Request:

```js
    {
        id: "button_id",
        state: { nclicks: 4 },
        val: null
    }
```

- Server's Response:
    1. Run the component's callback:
        - `res = component.callback(Config(nclicks=4), nothing)`
    2. If `res` isa `InnerHTML`

```js
    {
        id: "button_id",
        state: { nclicks: 5 },
        callback_response: {
            type: "InnerHTML",
            target: "target_internal_id",
            html: "Some string to set innerHTML to"
        }
    }
```

- Client acts on server response:
```js
states[data.id] = data.state
elements[data.target] = data.html
```
