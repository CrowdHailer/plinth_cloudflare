import conversation
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise.{type Promise}
import plinth/cloudflare/bindings
import plinth/cloudflare/r2

pub fn fetch(request, env, context) -> Promise(conversation.JsResponse) {
  let request = conversation.to_gleam_request(request)
  use body <- promise.await(conversation.read_bits(request.body))
  let assert Ok(body) = body
  let request = request.Request(..request, body: body)
  use response <- promise.map(handle(request, env, context))
  let response =
    response.Response(..response, body: conversation.Bits(response.body))
  conversation.to_js_response(response)
  // let response =
  //     response.new(200) |> response.set_body(conversation.Text("Conversation")),
  //   )
  // promise.resolve(response)
}

fn handle(request, env, _context) {
  case request.path_segments(request) {
    ["bindings", key] -> {
      case bindings.secret(env, key) {
        Ok(value) ->
          response.new(200)
          |> response.set_body(<<value:utf8>>)
          |> promise.resolve()
        Error(_) ->
          response.new(404)
          |> response.set_body(<<"not found":utf8>>)
          |> promise.resolve()
      }
    }
    ["r2", key] -> {
      let assert Ok(bucket) = bindings.r2_bucket(env, "MY_BUCKET")
      // echo request
      case request.method {
        http.Get -> {
          use return <- promise.await(r2.get(bucket, key, r2.get_options()))
          case return {
            Ok(body) -> {
              use raw <- promise.await(r2.read_bytes(body))
              let assert Ok(body) = raw
              response.new(200)
              |> response.set_body(body)
              |> promise.resolve()
            }
            Error(_) ->
              response.new(404)
              |> response.set_body(<<"not found":utf8>>)
              |> promise.resolve()
          }
        }
        http.Put -> {
          let value = request.body
          use return <- promise.await(r2.put(
            bucket,
            key,
            value,
            r2.put_options(),
          ))
          case return {
            Ok(_object) -> {
              response.new(200)
              |> response.set_body(<<>>)
              |> promise.resolve()
            }
            Error(_) ->
              response.new(404)
              |> response.set_body(<<"not found":utf8>>)
              |> promise.resolve()
          }
        }
        _ ->
          response.new(405)
          |> response.set_body(<<"method not allowed":utf8>>)
          |> promise.resolve()
      }
    }
    // ["r2"] -> {
    //   let assert Ok(_bucket) = bindings.r2_bucket(env, "MY_BUCKET")
    //   // use return <- promise.await(r2.list(bucket, key, r2.get_options()))
    //   todo as "implement list"
    // }
    _ -> panic
  }
}
