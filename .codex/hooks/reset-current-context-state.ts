#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { resetCurrentContextState } from
  "../../agentic_tools/hook_scripts/mention-current-context/mention-current-context-core";

type CodexHookInput = {
  session_id?: unknown;
};

const input = JSON.parse(readFileSync(0, "utf8")) as CodexHookInput;

if (typeof input.session_id !== "string" || !input.session_id) {
  throw new Error("Codex hook input is missing a valid session_id");
}

resetCurrentContextState("codex", input.session_id);
 