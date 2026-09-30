import type { Plugin } from "@opencode-ai/plugin";
import {
  mentionCurrentContextCore,
  resetCurrentContextState,
 } from
  "../../agentic_tools/hook_scripts/mention-current-context/mention-current-context-core";

const mentionCurrentContext: Plugin = async () => ({
  // primary hook for injecting the content of current_context.md
  "chat.message": async (input, output) => {
    const sessionId: string = input.sessionID;

    if (typeof sessionId !== "string" || !(sessionId)) {
      throw new Error(
        "OpenCode hook event is missing a valid sessionID",
      );
    }

    const runtime: string = "opencode";

    // if no text part, don't do anything
    const textPart = output.parts.find(
      (part) => part.type === "text" && !part.synthetic && !part.ignored,
    );
    if (textPart?.type !== "text") return;


    const message: string | null = mentionCurrentContextCore(
      runtime,
      sessionId
    );
    if (message !== null) {
      textPart.text = `${message}\n\n${textPart.text}`;
    }

    return;
  },

  // secondary hook for resetting the context state upon compaction
  // so upon next prompt submission, the context inject will work fine
  "experimental.session.compacting": async (input) => {
    resetCurrentContextState("opencode", input.sessionID);
  },
});

export default mentionCurrentContext;