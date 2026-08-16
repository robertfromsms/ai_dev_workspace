#!/usr/bin/env python3

import hashlib
import json
from pathlib import Path
import sys


hook_input = json.load(sys.stdin)
project_root = Path("/workspace")
current_context_path = project_root / "current_context.md"
state_directory = project_root / ".project-tmp" / "current-context-hook-state"

content = current_context_path.read_text(encoding="utf-8")
content_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
session_hash = hashlib.sha256(
    str(hook_input.get("session_id", "")).encode("utf-8")
).hexdigest()
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
