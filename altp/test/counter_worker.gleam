import altp
import conversation
import gleam/dynamic/decode
import gleam/http/response
import gleam/int
import gleam/javascript/promise
import gleam/json
import plinth/cloudflare/bindings

// run on the entry worker
pub fn fetch(_request, env, _ctx) {
  let assert Ok(namespace) = bindings.durable_object_namespace(env, "COUNTER")
  let counter = altp.lookup(namespace, "abc")
  use response <- promise.await(altp.call(counter, json.object([])))

  let assert Ok(response) = response
  let assert Ok(state) =
    json.parse(json.to_string(response), {
      decode.field("state", decode.int, decode.success)
    })
  let response =
    response.new(200)
    |> response.set_body(conversation.Text(int.to_string(state)))
  let response = conversation.to_js_response(response)
  promise.resolve(response)
}
