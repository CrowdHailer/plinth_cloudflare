import gleam/dict
import gleam/http
import gleam/http/request
import gleam/javascript/promise
import gleam/json
import gleam/option.{None}
import gleeunit
import miniflare

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn simple_worker_test() {
  let mf =
    miniflare.new(miniflare.default(), [
      miniflare.es("2025-06-17", "./test/simple_worker.mjs"),
    ])
  let request = request.new()
  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.status == 200
  assert response.body == "Hello Plinth!"
  promise.resolve(Nil)
}

pub fn bindings_test() {
  let worker =
    miniflare.es(
      "2025-06-17",
      "./build/dev/javascript/miniflare/test_worker_harness.js",
    )
  let worker =
    miniflare.WorkerOptions(
      ..worker,
      bindings: dict.from_list([#("MY_SECRET", json.string("ssssh"))]),
    )
  let mf = miniflare.new(miniflare.default(), [worker])
  let request =
    request.new()
    |> request.set_path("/bindings/MY_SECRET")
  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.status == 200
  assert response.body == "ssssh"
  promise.resolve(Nil)
}

pub fn r2_test() {
  let worker =
    miniflare.es(
      "2025-06-17",
      "./build/dev/javascript/miniflare/test_worker_harness.js",
    )
  let worker =
    miniflare.WorkerOptions(
      ..worker,
      r2_buckets: dict.from_list([#("MY_BUCKET", "MyBucket")]),
    )
  let mf = miniflare.new(miniflare.default(), [worker])

  // Get nothing
  let request =
    request.new()
    |> request.set_path("/r2/blobby")
  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.status == 404

  // Put something
  let request =
    request.new()
    |> request.set_method(http.Put)
    |> request.set_path("/r2/blobby")
    |> request.set_body("Crinkley Bottom")
  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.status == 200

  // List
  // let request =
  //   request.new()
  //   |> request.set_path("/r2")
  // use response <- promise.await(miniflare.fetch(mf, request))
  // let assert Ok(response) = response
  // assert response.status == 404

  // Get something
  let request =
    request.new()
    |> request.set_path("/r2/blobby")
  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.status == 200
  assert response.body == "Crinkley Bottom"

  promise.resolve(Nil)
}

pub fn queue_test() {
  let worker =
    miniflare.es(
      "2025-06-17",
      "./build/dev/javascript/miniflare/test_worker_harness.js",
    )
  let worker =
    miniflare.WorkerOptions(
      ..worker,
      queue_producers: dict.from_list([
        #("MY_QUEUE", miniflare.QueueProducerOptions("MyQueue", None)),
      ]),
      queue_consumers: dict.from_list([
        #(
          "MyQueue",
          miniflare.QueueConsumerOptions(None, None, None, None, None),
        ),
      ]),
    )
  let mf = miniflare.new(miniflare.default(), [worker])

  let request =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_path("/queue")
    |> request.set_body("Alton Towers")
  use response <- promise.await(miniflare.fetch(mf, request))
  let assert Ok(response) = response
  assert response.status == 201
  use _ <- promise.await(promise.wait(2000))
  // This test doesn't assert that the queue consumer has run, I just watched the logs.
  // Need a durable object or something else to make the test more rigorous.
  promise.resolve(Nil)
}
