import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}
import gleam/option.{None}
import plinth/cloudflare/durable_object as do

pub type Message {
  Call(payload: Dynamic, reply: fn(Json) -> Nil)
  Cast(payload: Dynamic)
}

pub fn lookup(namespace, name) {
  let id = do.id_from_name(namespace, name)
  do.get(namespace, id, None)
}

pub fn call(stub, message) {
  do.rpc(stub, "call", [message])
}
