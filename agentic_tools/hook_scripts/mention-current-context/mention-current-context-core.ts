import { createHash } from "node:crypto";
import {
  mkdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

function sha256(value: string): string {
  return createHash("sha256").update(value, "utf8").digest("hex");
}

export function mentionCurrentContextCore(
  runtime: string,
  sessionId: string,
): string | null{

    const projectRoot = "/workspace";
    const currentContextPath = join(
        projectRoot,
        "current_context.md",
    );
    const stateDirectory = join(
        projectRoot,
        ".project-tmp",
        "current-context-hook-state",
    );

    const content = readFileSync(currentContextPath, "utf8");
    const contentHash = sha256(content);
    const sessionHash = sha256(`${runtime}\0${sessionId}`);

    const statePath = join(
        stateDirectory,
        `${sessionHash}.sha256`,
    );

    let previousHash: string | null = null;

    try {
        previousHash = readFileSync(statePath, "utf8").trim();
    } 
    catch (error) {
        if (!(error instanceof Error) || !("code" in error) || error.code !== "ENOENT") {
            throw error;
        }
    }

    if (previousHash === contentHash) {
        return null;
    }

    mkdirSync(stateDirectory, { recursive: true });
    writeFileSync(statePath, `${contentHash}\n`, "utf8");

    if (content.trim()) {
        return (
            "The following is the latest user-maintained current_context.md. " +
            "It supersedes any earlier version of that file in the conversation.\n\n" +
            content
        );
    } 
    else if (previousHash !== null) {
        return (
            "current_context.md is now blank. Disregard any earlier version of " +
            "that file in the conversation."
        );
    }

    return null;
}