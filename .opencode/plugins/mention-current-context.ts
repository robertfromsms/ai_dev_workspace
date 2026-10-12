import { Plugin } from "@opencode/plugin";
import {
  mentionCurrentContextCore,
  resetCurrentContextState,
} from "../../agentic_tools/hook_scripts/mention-current-context/mention-current-context-core";

export default Plugin.define({
  id: "mention-current-context",

  async setup(ctx) {
    await ctx.session.hook("prompt", (event) => {
      const sessionId = event.sessionID;

      if (typeof sessionId !== "string" || !sessionId) {
        throw new Error("OpenCode prompt hook is missing a valid sessionID");
      }

      // do nothing when there is no user prompt text.
      if (!event.prompt.text) return;

      const message = mentionCurrentContextCore("opencode", sessionId);
      if (message === null) return;

      const prefix = `${message}\n\n`;
      const offset = prefix.length;

      // opencode records positions of @mentions within the prompt text. Prepending
      // the context moves those mentions, so update their positions too.
      const shiftMentions = <
        T extends { mention?: { start: number; end: number } },
      >(
        items: readonly T[] | undefined,
      ): T[] | undefined =>
        items?.map((item) =>
          item.mention
            ? {
                ...item,
                mention: {
                  ...item.mention,
                  start: item.mention.start + offset,
                  end: item.mention.end + offset,
                },
              }
            : item,
        );

      event.prompt.files = shiftMentions(event.prompt.files);
      event.prompt.agents = shiftMentions(event.prompt.agents);
      event.prompt.skills = shiftMentions(event.prompt.skills);
      event.prompt.text = `${prefix}${event.prompt.text}`;
    });

    await ctx.session.hook("compaction", (event) => {
      resetCurrentContextState("opencode", event.sessionID);
    });
  },
});