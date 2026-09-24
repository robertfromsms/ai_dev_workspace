import { Plugin } from "@opencode/plugin";
import type { SessionPrompt } from "@opencode/plugin/promise/session";
import type { PluginContext } from "@opencode-ai/plugin/v2/promise";
import { mentionCurrentContextCore } from
  "../../agentic_tools/hook_scripts/mention-current-context/mention-current-context-core";

export default Plugin.define({
  id: "mention-current-context",

  async setup(ctx: PluginContext) {
    await ctx.session.hook("prompt", (event: SessionPrompt) => {
      const sessionId: string = event.sessionID;

      if (typeof sessionId !== "string" || !(sessionId)) {
        throw new Error(
          "OpenCode hook event is missing a valid sessionID",
        );
      }

      const runtime: string = "opencode";

      const message: string | null = mentionCurrentContextCore(
        runtime,
        sessionId,
      );

      if (message === null) {
        return;
      }

      event.prompt.text =
        `${message}\n\n${event.prompt.text}`;
    });
  },
});