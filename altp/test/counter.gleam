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
