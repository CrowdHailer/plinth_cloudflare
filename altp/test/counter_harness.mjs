import { Actor } from "./altp/actor.mjs";
import { init, handle } from "./counter.mjs";
import { fetch } from "./altp_test.mjs";


export class Counter extends Actor {
  constructor(ctx, env) {
    super(ctx, env);
  }

  init(env) {
    return init(env);
  }
  
  handle(state,message) {
    return handle(state, message);
  }
}

// This probably would be a separate file in a larger system
export default {
  async fetch(request, env, ctx) {
    return await fetch(request, env, ctx)
  },
};