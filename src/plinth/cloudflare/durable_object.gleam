import gleam/javascript/promise.{type Promise}
import gleam/json

pub type Namespace

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "id_from_name")
pub fn id_from_name(namespace: Namespace, name: String) -> Id

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "new_unique_id")
fn do_new_unique_id(jurisdiction: json.Json) -> Id

pub fn new_unique_id(jurisdiction) {
  let options =
    json.nullable(jurisdiction, fn(j) {
      json.object([#("jurisdiction", json.string(j))])
    })
  do_new_unique_id(options)
}

/// This is the string value of the objects id, not its name.
@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "id_from_string")
pub fn id_from_string(namespace: Namespace, id: String) -> Id

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "get")
pub fn do_get(namespace: Namespace, id: Id, options: json.Json) -> Stub

pub fn get(namespace, id, location_hint) {
  let options =
    json.nullable(location_hint, fn(hint) {
      json.object([#("locationHint", json.string(hint))])
    })
  do_get(namespace, id, options)
}

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "jurisdiction")
pub fn jurisdiction(namespace: Namespace, jurisdiction: String) -> Namespace

pub type Id

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "to_string")
pub fn to_string(id: Id) -> String

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "equals")
pub fn equals(id: Id, other: Id) -> Bool

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "name")
pub fn name(id: Id) -> String

pub type Stub

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "stub_id")
pub fn stub_id(state: Stub) -> Id

pub type State

// @deprecated("A Durable Object will remain active for at least 70 seconds after the last client disconnects if the Durable Object is still waiting on any ongoing work or outbound I/O. So waitUntil is not necessary. It remains part of the DurableObjectState interface to remain compatible with Workers Runtime APIs.")
// pub fn wait_until() 

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "block_concurrency_while")
pub fn block_concurrency_while(
  state: State,
  action: fn() -> Promise(t),
) -> Promise(t)

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "state_id")
pub fn state_id(state: State) -> Id

@external(javascript, "../../plinth_cloudflare_durable_object_ffi.mjs", "storage")
pub fn storage(state: State) -> Storage

pub type Storage
