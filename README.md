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
