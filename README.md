# plinth_cloudflare

[![Package Version](https://img.shields.io/hexpm/v/plinth_cloudflare)](https://hex.pm/packages/plinth_cloudflare)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/plinth_cloudflare/)

```sh
gleam add plinth_cloudflare@1
```
```gleam
import plinth/cloudflare/bindings
import plinth/cloudflare/r2

pub fn fetch(request, env)  {
  let assert Ok(bucket) = bindings.r2_bucket(env, "MY_BUCKET")
  use return <- promise.await(r2.get(bucket, "my-key", options))
  case return {
    Ok(content) ->
    Error(_) -> {
      use return <- promise.await(r2.put(bucket, "my-key", options))
    }
  }
}
```

Further documentation can be found at <https://hexdocs.pm/plinth_cloudflare>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Notes

### Reusing Id's

Getting an instance with the same Id will get access to the running flow, even if it has completed.
Workflows can be explicitly restarted.
Workflows do upgrade if restarted.

https://blog.cloudflare.com/workflows-ga-production-ready-durable-execution/


## Questions

### Do Gleam objects containing data types get serialized correctly?

They do not get serialized correctly.
The method for serialization is the [structured clone algorithm](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm). The experiment with `postMessage` shows that an Ok type is not sent.
The [cloudflare version](https://developers.cloudflare.com/workers/runtime-apis/rpc/#structured-clonable-types-and-more) supports slightly more data types than the web version.
It supports application classes that extend `RpcTarget` but implementing this would require changes in the Gleam compiler.

User `Json` type to send data and potentially automatically decode for compound operations in `Flo`.
Plinth uses `Json` for postMessage, dagJson could allow sending binary to be easier.

TODO test if the classes are serialized when retrying but the workflow has not been restarted

```js
window.addEventListener('message', function(event) {
  console.log('Received message:', event.data);
  console.log('is Ok:', event.data.isOk && event.data.isOk());
  // This there is no isOk method on the data
});

window.postMessage('Hello, self!', '*');

class Ok {
  constructor(value) {
    // super();
    this[0] = value;
  }

  // @internal
  isOk() {
    return true;
  }
}

let value = new Ok(5)

console.log("before send", value.isOk())
// This returns true

window.postMessage(value, '*');
```

`isOk` is used in case so crucial that it is restored https://gleam.run/news/gleam-javascript-gets-30-percent-faster/

[The Ok definition](https://github.com/gleam-lang/gleam/blob/d3f4d9974b8a71002cb245c7317674643afc1fc5/compiler-core/templates/prelude.mjs#L1445)

### How are steps cached is it based on name, or name and position

TODO find a better example with looping

This blog post does a good job of showing what happens inside
https://blog.cloudflare.com/building-workflows-durable-execution-on-workers/#observability

TODO can I look with the same name

```js
let firstReturn = await step.do("same", async () => {
  console.log("first step")
  return "first step"
})
let secondReturn = await step.do("same", async () => {
  console.log("second step")
  if (x == 0) {
    x += 1
    throw "bad"
  }
  return "second step"
})
let final = Promise.all([firstReturn, secondReturn])
console.log("final", await final)
```

This runs correctly as long as the engine doesn't restart

### Do not rely on side effects of steps

The docs state [do note rely on STATE outside of a step]https://developers.cloudflare.com/workflows/build/rules-of-workflows/#do-not-rely-on-state-outside-of-a-step

I think that it's not so much "outside the step" but the steps side effects builds the list.

My best understanding is that calling `step.do` is implemented and runtime, No compiler tricks to find calls like in some meta frameworks.
When a step fails, but the engine is not restarted. That action for the failing step is restarted. 
If the engine is restarted then the script is run again, calls to `step.do` automatically return the previous output, and the script continues

```js
const x = await step.do("first step", async () => {
  const x = Math.random()
  return x
})

const y = Math.random()

const z = await step.do("second step", async () => {
  const z = Math.random()
  throw new Error("recoverable error")
})
```

So while the engine stays running the value of `y` is constant for each retry.
If the engine is restarted then `y` is recalculated.

If y was purely derived from x then it would be fine to calculate it outside of a step.


### Do steps that are not awaited on execute in parallel

The docs are not clear on this but do mention the use of promise await/all
