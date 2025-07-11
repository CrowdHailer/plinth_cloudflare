import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/result
import plinth/cloudflare/durable_object as do
import plinth/cloudflare/r2
import plinth/cloudflare/workflow

pub fn r2_bucket(env, binding) {
  use raw <- result.try(get(env, binding))
  cast_to_r2_bucket(raw)
}

pub fn durable_object_namespace(env, binding) {
  use raw <- result.try(get(env, binding))
  cast_to_durable_object_namespace(raw)
}

pub fn workflow(env, binding) {
  use raw <- result.try(get(env, binding))
  cast_to_workflow(raw)
}

pub fn secret(env, key) {
  let decoder = decode.field(key, decode.string, decode.success)
  decode.run(env, decoder)
}

@external(javascript, "../../plinth_cloudflare_bindings_ffi.mjs", "get")
fn get(env: Dynamic, key: String) -> Result(Dynamic, Nil)

@external(javascript, "../../plinth_cloudflare_bindings_ffi.mjs", "cast_to_r2_bucket")
fn cast_to_r2_bucket(raw: Dynamic) -> Result(r2.Bucket, Nil)

@external(javascript, "../../plinth_cloudflare_bindings_ffi.mjs", "cast_to_durable_object_namespace")
fn cast_to_durable_object_namespace(raw: Dynamic) -> Result(do.Namespace, Nil)

@external(javascript, "../../plinth_cloudflare_bindings_ffi.mjs", "cast_to_workflow")
fn cast_to_workflow(raw: Dynamic) -> Result(workflow.Workflow, Nil)
