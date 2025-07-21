import { Ok, Error } from "./gleam.mjs";
import { Miniflare, Log, NoOpLog } from "miniflare";
import { NetworkError } from "../gleam_fetch/gleam/fetch.mjs";
import { Some } from "../gleam_stdlib/gleam/option.mjs";

export function log(level, options) {
  return new Log(level, options)
}

export function no_op_log() {
  return new NoOpLog()
}

export function new_(opts) {
  return new Miniflare(opts)
}

export function set_options(miniflare, opts) {
  return miniflare.setOptions(opts)
}

export function ready(miniflare) {
  return miniflare.ready
}

export async function dispatch_fetch(miniflare, request) {
  // Passing this fetch request directly to miniflare causes an error
  // 
  // I am not sure why this error happens and going through similar steps to miniflare internals doesnt have the same issue
  // console.log(new Request(request, undefined))


  let init = {
    method: request.method,
    body: request.body,
    // duplex: half needed because sending request body as a readable stream
    duplex: "half"
  }
  try {
    return new Ok(await miniflare.dispatchFetch(request.url, init))
  } catch (error) {
    return new Error(new NetworkError(error.toString()))
  }
}

export function get_bindings(miniflare, worker_name) {
  worker_name = worker_name instanceof Some ? worker_name[0] : undefined
  return miniflare.getBindings(worker_name)
}

export function get_worker(miniflare, worker_name) {
  worker_name = worker_name instanceof Some ? worker_name[0] : undefined
  return miniflare.getWorker(worker_name)
}

export function get_d1_database(miniflare, binding_name, worker_name) {
  worker_name = worker_name instanceof Some ? worker_name[0] : undefined
  return miniflare.getD1Database(binding_name, worker_name)
}

export function get_durable_object_namespace(miniflare, binding_name, worker_name,) {
  worker_name = worker_name instanceof Some ? worker_name[0] : undefined
  return miniflare.getDurableObjectNamespace(binding_name, worker_name)
}

export function get_r2_bucket(miniflare, binding_name, worker_name) {
  worker_name = worker_name instanceof Some ? worker_name[0] : undefined
  return miniflare.getR2Bucket(binding_name, worker_name)
}

export function unsafe_to_json(any) {
  return any
}