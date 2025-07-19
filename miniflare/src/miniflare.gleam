import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/fetch
import gleam/javascript/promise.{type Promise}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import plinth/cloudflare/d1
import plinth/cloudflare/durable_object as do
import plinth/cloudflare/r2
import plinth/cloudflare/utils

pub type ModuleRuleType {
  ESModule
  CommonJS
  Text
  Data
  CompiledWasm
}

pub type ModuleDefinition {
  ModuleDefinition(
    type_: ModuleRuleType,
    path: String,
    // modded unit8
    contents: Option(String),
  )
}

pub type ModuleRule {
  ModuleRule(
    type_: ModuleRuleType,
    include: List(String),
    fallthrough: Option(Bool),
  )
}

pub type Persistence {
  PersistenceBool(Bool)
  PersistenceString(String)
  PersistenceUndefined
}

pub type LogLevel {
  NONE
  ERROR
  WARN
  INFO
  DEBUG
  VERBOSE
}

pub type LogOptions {
  LogOptions(prefix: Option(String), suffix: Option(String))
}

pub type Log {
  Log(level: Option(LogLevel), opts: Option(LogOptions))
}

pub type NoOpLog {
  NoOpLog
}

pub type QueueProducerOptions {
  QueueProducerOptions(queue_name: String, delivery_delay: Option(Int))
}

fn queue_producer_options_to_arg(options) {
  let QueueProducerOptions(queue_name, delivery_delay) = options
  utils.sparse([
    #("queueName", json.string(queue_name)),
    #("deliveryDelay", json.nullable(delivery_delay, json.int)),
  ])
}

pub type QueueConsumerOptions {
  QueueConsumerOptions(
    max_batch_size: Option(Int),
    max_batch_timeout: Option(Int),
    max_retries: Option(Int),
    dead_letter_queue: Option(String),
    retry_delay: Option(Int),
  )
}

fn queue_consumer_options_to_arg(options) {
  let QueueConsumerOptions(
    max_batch_size,
    max_batch_timeout,
    max_retries,
    dead_letter_queue,
    retry_delay,
  ) = options
  utils.sparse([
    #("maxBatchSize", json.nullable(max_batch_size, json.int)),
    #("maxBatchTimeout", json.nullable(max_batch_timeout, json.int)),
    #("maxRetries", json.nullable(max_retries, json.int)),
    #("deadLetterQueue", json.nullable(dead_letter_queue, json.string)),
    #("retryDelay", json.nullable(retry_delay, json.int)),
  ])
}

pub type Modules {
  ESModules
  ServiceWorkerFormat
  // Modules list not supported yet
  // ModulesList(List(ModuleDefinition))
}

pub fn modules_to_arg(modukes) {
  case modukes {
    ESModules -> json.bool(True)
    ServiceWorkerFormat -> json.bool(False)
    // ModulesList(_) -> panic as
  }
}

pub type WorkerOptions {
  WorkerOptions(
    name: Option(String),
    root_path: Option(String),
    script: Option(String),
    script_path: Option(String),
    modules: Modules,
    modules_root: Option(String),
    // modules_rules: Option(List(ModuleRule)),
    compatibility_date: Option(String),
    // compatibility_flags: Option(List(String)),
    bindings: Dict(String, Json),
    // wasm_bindings: Option(Dict(String, String)),
    // text_blob_bindings: Option(Dict(String, String)),
    // data_blob_bindings: Option(Dict(String, String)),
    // service_bindings: Option(Dict(String, String)),
    // wrapped_bindings: Option(Dict(String, String)),
    // outbound_service: Option(String),
    // fetch_mock: Option(String),
    // routes: Option(List(String)),
    // default_persist_root: Option(String),
    // cache: Option(Bool),
    // cache_warn_usage: Option(Bool),
    // durable_objects: Option(Dict(String, String)),
    // kv_namespaces: Option(Dict(String, String)),
    // site_path: Option(String),
    // site_include: Option(List(String)),
    // site_exclude: Option(List(String)),
    // assets_path: Option(String),
    // assets_kv_binding_name: Option(String),
    // assets_manifest_binding_name: Option(String),
    r2_buckets: Dict(String, String),
    // d1_databases: Option(Dict(String, String)),
    queue_producers: Dict(String, QueueProducerOptions),
    queue_consumers: Dict(String, QueueConsumerOptions),
    // directory: Option(String),
    // binding: Option(String),
    // asset_options: Option(Dict(String, String)),
    // pipelines: Option(Dict(String, String)),
    // workflows: Option(List(String)),
    // browser_rendering: Option(String),
  )
}

fn empty() {
  WorkerOptions(
    name: None,
    root_path: None,
    script: None,
    script_path: None,
    modules: ESModules,
    modules_root: None,
    compatibility_date: None,
    bindings: dict.new(),
    r2_buckets: dict.new(),
    queue_producers: dict.new(),
    queue_consumers: dict.new(),
  )
}

pub fn es(path) {
  WorkerOptions(..empty(), script_path: Some(path))
}

fn worker_options_to_arg(opts: WorkerOptions) {
  [
    #("name", option.map(opts.name, json.string)),
    #("rootPath", option.map(opts.root_path, json.string)),
    #("script", option.map(opts.script, json.string)),
    #("scriptPath", option.map(opts.script_path, json.string)),
    #("modules", Some(modules_to_arg(opts.modules))),
    #("modulesRoot", option.map(opts.modules_root, json.string)),
    #("compatibilityDate", option.map(opts.compatibility_date, json.string)),
    #("bindings", optional_dict(opts.bindings, id)),
    #("r2Buckets", optional_dict(opts.r2_buckets, json.string)),
    #(
      "queueProducers",
      optional_dict(opts.queue_producers, queue_producer_options_to_arg),
    ),
    #(
      "queueConsumers",
      optional_dict(opts.queue_consumers, queue_consumer_options_to_arg),
    ),
  ]
  |> list.filter_map(is_some_value)
  |> json.object
}

fn optional_dict(dict, value_encoder) {
  case dict.is_empty(dict) {
    True -> None
    False -> Some(json.dict(dict, id, value_encoder))
  }
}

fn id(x) {
  x
}

pub type SharedOptions {
  SharedOptions(
    /// Path against which all other path options for this instance are resolved relative to. Defaults to the current working directory.
    root_path: Option(String),
    host: Option(String),
    port: Option(Int),
    https: Option(Bool),
    https_key: Option(String),
    https_key_path: Option(String),
    https_cert: Option(String),
    https_cert_path: Option(String),
    inspector_port: Option(Int),
    verbose: Option(Bool),
    log: Option(Log),
    upstream: Option(String),
    // cf: Option(Dict(String, Json)),
    live_reload: Option(Bool),
    cache_persist: Option(Persistence),
    durable_objects_persist: Option(Persistence),
    kv_persist: Option(Persistence),
    r2_persist: Option(Persistence),
    d1_persist: Option(Persistence),
    workflows_persist: Option(Persistence),
  )
}

fn shared_options_to_entries(opts: SharedOptions) {
  [
    #("rootPath", option.map(opts.root_path, json.string)),
    #("host", option.map(opts.host, json.string)),
    #("port", option.map(opts.port, json.int)),
    #("https", option.map(opts.https, json.bool)),
    #("httpsKey", option.map(opts.https_key, json.string)),
    #("httpsKeyPath", option.map(opts.https_key_path, json.string)),
    #("httpsCert", option.map(opts.https_cert, json.string)),
    #("httpsCertPath", option.map(opts.https_cert_path, json.string)),
    #("inspectorPort", option.map(opts.inspector_port, json.int)),
    #("verbose", option.map(opts.verbose, json.bool)),
    // #("log", option.map(opts.log, log_to_json)),
    #("upstream", option.map(opts.upstream, json.string)),
    // #("cf", option.map(opts.cf, json.object)),
    #("liveReload", option.map(opts.live_reload, json.bool)),
    // #("cachePersist", option.map(opts.cache_persist, persistence_to_json)),
  // #(
  //   "durableObjectsPersist",
  //   option.map(opts.durable_objects_persist, persistence_to_json),
  // ),
  // #("kvPersist", option.map(opts.kv_persist, persistence_to_json)),
  // #("r2Persist", option.map(opts.r2_persist, persistence_to_json)),
  // #("d1Persist", option.map(opts.d1_persist, persistence_to_json)),
  // #(
  //   "workflowsPersist",
  //   option.map(opts.workflows_persist, persistence_to_json),
  // ),
  ]
  |> list.filter_map(is_some_value)
}

fn is_some_value(entry) {
  let #(k, v) = entry
  v
  |> option.map(pair.new(k, _))
  |> option.to_result(Nil)
}

pub type MiniflareOptions {
  MiniflareOptions(
    shared_options: SharedOptions,
    worker_options: List(WorkerOptions),
  )
}

pub fn default() {
  SharedOptions(
    root_path: None,
    host: None,
    port: None,
    https: None,
    https_key: None,
    https_key_path: None,
    https_cert: None,
    https_cert_path: None,
    inspector_port: None,
    verbose: None,
    log: None,
    upstream: None,
    // cf: None,
    live_reload: None,
    cache_persist: None,
    durable_objects_persist: None,
    kv_persist: None,
    r2_persist: None,
    d1_persist: None,
    workflows_persist: None,
  )
}

pub type Miniflare {
  Miniflare(opts: MiniflareOptions)
}

/// Creates a Miniflare instance and starts a new `workerd` HTTP server listening on the configured `host` and `port`.
@external(javascript, "./miniflare_ffi.mjs", "new_")
fn do_new(opts: Json) -> Miniflare

pub fn new(shared_options, worker_options) {
  let options =
    json.object([
      #("workers", json.array(worker_options, worker_options_to_arg)),
      ..shared_options_to_entries(shared_options)
    ])
  do_new(options)
}

@external(javascript, "./miniflare_ffi.mjs", "set_options")
pub fn set_options(miniflare: Miniflare, opts: MiniflareOptions) -> Nil

// TODO check returns string not url
@external(javascript, "./miniflare_ffi.mjs", "ready")
pub fn ready(miniflare: Miniflare) -> Promise(String)

/// Takes a request as defined by undici.
/// https://github.com/cloudflare/workers-sdk/blob/c7de92e8702da59fd0858147192c2a70abfb35e9/packages/miniflare/src/http/request.ts#L1-L5
/// 
/// undici fetch implement Web fetch
/// https://github.com/nodejs/undici?tab=readme-ov-file#undicifetchinput-init-promise
@external(javascript, "./miniflare_ffi.mjs", "dispatch_fetch")
pub fn dispatch_fetch_raw(
  miniflare: Miniflare,
  request: fetch.FetchRequest,
) -> Promise(Result(fetch.FetchResponse, fetch.FetchError))

pub fn fetch(miniflare, request) {
  let request = fetch.to_fetch_request(request)
  use response <- promise.try_await(dispatch_fetch_raw(miniflare, request))
  let response = fetch.from_fetch_response(response)
  fetch.read_text_body(response)
}

@external(javascript, "./miniflare_ffi.mjs", "get_bindings")
pub fn get_bindings(
  miniflare: Miniflare,
  worker_name: Option(String),
) -> Promise(Dynamic)

/// A fetcher is the class that is a worker
/// This type signature cannot be represented in Gleam
/// The best effort might be to assume `fetch`, `connect`, `queue` and `scheduled`
/// And additionally offer a to dynamic or rpc interface
/// https://workers-types.pages.dev/experimental/#Fetcher
pub type Fetcher

@external(javascript, "./miniflare_ffi.mjs", "get_worker")
pub fn get_worker(
  miniflare: Miniflare,
  worker_name: Option(String),
) -> Promise(Fetcher)

// @external(javascript, "./miniflare_ffi.mjs", "get_caches")
// pub fn get_caches(miniflare: Miniflare) -> Promise(CacheStorage)

@external(javascript, "./miniflare_ffi.mjs", "get_d1_database")
pub fn get_d1_database(
  miniflare: Miniflare,
  binding_name: String,
  worker_name: Option(String),
) -> Promise(d1.Database)

@external(javascript, "./miniflare_ffi.mjs", "get_durable_object_namespace")
pub fn get_durable_object_namespace(
  miniflare: Miniflare,
  binding_name: String,
  worker_name: Option(String),
) -> Promise(do.Namespace)

// @external(javascript, "./miniflare_ffi.mjs", "get_kv_namespace")
// pub fn get_kv_namespace(
//   miniflare: Miniflare,
//   binding_name: String,
//   worker_name: Option(String),
// ) -> Promise(KVNamespace)

// @external(javascript, "./miniflare_ffi.mjs", "get_queue_producer")
// pub fn get_queue_producer(
//   miniflare: Miniflare,
//   binding_name: String,
//   worker_name: Option(String),
// ) -> Promise(Queue)

@external(javascript, "./miniflare_ffi.mjs", "get_r2_bucket")
pub fn get_r2_bucket(
  miniflare: Miniflare,
  binding_name: String,
  worker_name: Option(String),
) -> Promise(r2.Bucket)
// @external(javascript, "./miniflare_ffi.mjs", "dispose")
// pub fn dispose(miniflare: Miniflare) -> Promise(Nil)

// @external(javascript, "./miniflare_ffi.mjs", "get_cf")
// pub fn get_cf(miniflare: Miniflare) -> Promise(Dict(String, Dynamic))
