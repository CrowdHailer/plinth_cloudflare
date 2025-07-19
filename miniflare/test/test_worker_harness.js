import { fetch, queue } from "./test_worker.mjs"

export default {
  async fetch(request, env, ctx) {
    return await fetch(request, env, ctx)
  },

  async queue(batch, env) {
    return await queue(batch, env)
  },
};
