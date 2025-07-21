import gleam/dict
import gleam/http/request
import gleam/javascript/promise
import miniflare

// The test code has to not be imported by any worker code as miniflare/gleeunit will not run on worker
pub fn counter_test() {
  let worker =
    miniflare.es(
      "2025-06-17",
      "./build/dev/javascript/altp/counter_harness.mjs",
    )
  let worker =
    miniflare.WorkerOptions(
      ..worker,
      durable_objects: dict.from_list([#("COUNTER", "Counter")]),
    )
  let mf = miniflare.new(miniflare.default(), [worker])
  let request = request.new()
  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.body == "0"

  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.body == "1"

  promise.resolve(Nil)
}
