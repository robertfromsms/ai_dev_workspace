#!/usr/bin/env python3

import argparse
import hashlib
import json
from pathlib import Path
import sys


def get_session_hash(runtime: str, hook_input: dict) -> str:
    match runtime:
        case "codex":
            session_id = hook_input.get("session_id")
            if not isinstance(session_id, str) or not session_id:
                raise ValueError("Codex hook input is missing a valid session_id")
            session_key = f"{runtime}\0{session_id}"
            return hashlib.sha256(session_key.encode("utf-8")).hexdigest()

        case _:
            raise ValueError(f"Agentic runtime not recognized: {runtime}")


parser = argparse.ArgumentParser()
parser.add_argument("--runtime", required=True)
args = parser.parse_args()

hook_input = json.load(sys.stdin)
project_root = Path("/workspace")
current_context_path = project_root / "current_context.md"
state_directory = project_root / ".project-tmp" / "current-context-hook-state"

content = current_context_path.read_text(encoding="utf-8")
content_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
session_hash = get_session_hash(args.runtime, hook_input)
state_path = state_directory / f"{session_hash}.sha256"

try:
    previous_hash = state_path.read_text(encoding="utf-8").strip()
except FileNotFoundError:
    previous_hash = None

if previous_hash == content_hash:
    raise SystemExit(0)

state_directory.mkdir(parents=True, exist_ok=True)
state_path.write_text(f"{content_hash}\n", encoding="utf-8")

if content.strip():
    print(
        "The following is the latest user-maintained current_context.md. "
        "It supersedes any earlier version of that file in the conversation.\n\n"
        f"{content}",
        end="",
    )
elif previous_hash is not None:
    print(
        "current_context.md is now blank. Disregard any earlier version of "
        "that file in the conversation.",
        end="",
    )
