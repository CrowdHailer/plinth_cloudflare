import { Call, Cast } from "../../altp/altp.mjs"
// import { Some } from "../gleam_stdlib/gleam/option.mjs";
import { DurableObject } from "cloudflare:workers";

// Transient Actor dies on code upgrade
export class Actor extends DurableObject {
  constructor(ctx, env) {
    // The id name is not available here even when set when creating the stub
    super(ctx, env);
    this.mailbox = [];
    // Handling is set to true so messages are queued while the actor is initializing
    this.handling = true;
    const self = this
    // constructor cannot be async so we use `.then` API.
    this.init(ctx, env).then(async function (value) {
      // this is not bound to the durable object instance when handling the promise callback
      // All handlings need to set and immediate alarm after to check
      await ctx.storage.setAlarm(Date.now() + 0);
      self.state = value;
      self.handling = false;
    })
  }

  // call, and cast, always push to the mailbox and set an alarm to handle the message.
  // This leaves one place to handle processing messages, the alarm handler.
  async call(payload) {
    let resolve;
    const promise = new Promise((r) => (resolve = r));
    this.mailbox.push({ payload, resolve });
    await this.ctx.storage.setAlarm(Date.now() + 0);
    return await promise;
  }

  async cast(payload) {
    this.mailbox.push({ payload });
    await this.ctx.storage.setAlarm(Date.now() + 0);
    return null;
  }

  async alarm(info) {
    // No alarm needs to be set here, the current handler will always set an alarm to check
    if (this.handling) return;

    const pending = this.mailbox.shift();
    // Put any alarms that might have happened in the mailbox
    if (pending) {
      this.handling = true;
      const { payload, resolve } = pending;
      const message = resolve ? new Call(payload, resolve) : new Cast(payload);
      const next = await this.handle(this.state, message);
      await this.ctx.storage.setAlarm(Date.now() + 0);
      this.state = next
      this.handling = false
    }
  }

  // These methods should be overridden by the actor
  // Having this stubs throw an error gave very poor error messages.
  // Logging is better
  async init() {
    console.warn("Actor.init() is not implemented");
    return null
  }

  async handle() {
    console.warn("Actor.handle() is not implemented");
    return null
  }
}