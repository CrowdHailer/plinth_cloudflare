import { Ok, Error } from "./gleam.mjs";
export function id_from_name(namespace, name) {
  return namespace.idFromName(name)
}

export function new_unique_id(namespace) {
  return namespace.newUniqueId()
}

export function id_from_string(namespace, id) {
  return namespace.idFromString(id)
}

export function get(namespace, id, options) {
  return namespace.get(id, options)
}

export function jurisdiction(namespace, j) {
  return namespace.jurisdiction(j)
}

export function to_string(id) {
  return id.toString()
}

export function equals(id1, id2) {
  return id1.equals(id2)
}

export function name(id) {
  return id.name
}

export function stub_id(stub) {
  return stub.id
}

export async function rpc(stub, method,args) {
  try {
    return new Ok(await stub[method](...args))
  } catch (error) {
    return new Error(`${error}`)
  }
}

export function block_concurrency_while(state, f) {
  return state.blockConcurrencyWhile(f)
}

export function state_id(state) {
  return state.id
}

export function storage(state) {
  return state.storage
}