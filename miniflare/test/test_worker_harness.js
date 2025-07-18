import {fetch} from "./test_worker.mjs"

export default {
  async fetch(request, env, ctx) {
    return await fetch(request, env, ctx)
  },
};
