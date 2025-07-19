# altp

Experimental implementation of Actors for Cloudflare Workers using Durable Objects.

[![Package Version](https://img.shields.io/hexpm/v/altp)](https://hex.pm/packages/altp)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/altp/)

```sh
gleam add altp@1
```

Implement the init and handle functions of your actor.

```rs
import altp
import gleam/javascript/promise
import gleam/json
import plinth/cloudflare/durable_object as do

pub fn init(_ctx: do.State, _env) {
  promise.resolve(0)
}

pub fn handle(state, message) {
  case message {
    altp.Call(_, reply) -> reply(json.object([#("state", json.int(state))]))
    altp.Cast(_) -> Nil
  }
  promise.resolve(state + 1)
}
```

Use in a Cloudflare Durable Object.
```js
import { Actor } from "./altp/actor.mjs";
import { init, handle } from "./counter.mjs";

export class Counter extends Actor {
  constructor(ctx, env) {
    super(ctx, env);
  }

  init(env) {
    return init(env);
  }
  
  handle(state,message) {
    return handle(state, message);
  }
}
```

Call and use your actor.
```rs
pub fn fetch(_request, env, _ctx) {
  let assert Ok(namespace) = bindings.durable_object_namespace(env, "COUNTER")
  let counter = altp.lookup(namespace, "abc")
  use response <- promise.await(altp.call(counter, json.object([])))
  // Do something with the response
}
```

Further documentation can be found at <https://hexdocs.pm/altp>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
