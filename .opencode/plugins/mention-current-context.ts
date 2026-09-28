import type { Plugin } from "@opencode-ai/plugin";
import { mentionCurrentContextCore } from
  "../../agentic_tools/hook_scripts/mention-current-context/mention-current-context-core";

const mentionCurrentContext: Plugin = async () => ({
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
});

export default mentionCurrentContext;