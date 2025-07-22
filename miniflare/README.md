# 🔥 Miniflare

**Miniflare** is a simulator for developing and testing [Cloudflare Workers](https://workers.cloudflare.com/). The runtime is powered by [workerd](https://github.com/cloudflare/workerd) and opensource JavaScript/Wasm [server first runtime](https://blog.cloudflare.com/workerd-open-source-workers-runtime/).

[![Package Version](https://img.shields.io/hexpm/v/miniflare)](https://hex.pm/packages/miniflare)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/miniflare/)

Refer to the tests for running examples.

```sh
npm i -s miniflare@4
gleam add miniflare@1
```

```gleam
import miniflare

pub fn main() -> Nil {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/miniflare>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
// https://developers.cloudflare.com/workers/testing/miniflare/get-started/#reference
// https://cf-miniflare.pages.dev/core/standards#mocking-outbound-fetch-requests
