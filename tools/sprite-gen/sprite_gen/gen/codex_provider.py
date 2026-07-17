# SPDX-License-Identifier: Apache-2.0
"""Codex `image_gen` provider (ChatGPT OAuth, no API key).

Ported from the standalone `image-gen` skill (MIT, aldegad/image-gen). codex
does not persist a discrete file; `image_gen` returns the PNG **inline as base64**
inside the session rollout jsonl. We spawn a fresh `codex exec` in an empty
sandbox (fresh session breaks OpenAI's prompt cache so repeat prompts don't drag
in a previous image), parse the session id from stdout, then decode the inline
base64 deterministically. The model-reported path is never trusted.

Decisive flags (each verified in the image-gen skill):
- `--sandbox workspace-write`  image_gen needs write access, else the tool never registers.
- `--add-dir ~/.codex/generated_images`  not in the default writable set; missing it silently fails.
- `--skip-git-repo-check`  the sandbox dir is not a git repo.
- NO `--ephemeral`  the session jsonl must survive on disk so we can extract from it.
"""

from __future__ import annotations

import base64
import glob
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

from .base import GenRequest, ProviderRun, verify_png

# codex carries the inline base64 on a version-specific record. Both are
# first-class canonical records (not a fallback) — read whichever the running
# codex emits. v0.140.0: response_item `image_generation_call`. v0.144.1:
# event_msg `image_generation_end` (+status, saved_path — saved_path untrusted).
_RESULT_TYPES = ("image_generation_call", "image_generation_end")
# The session id that names the rollout jsonl. v0.144.1 `codex exec --json` emits
# it as `{"type":"thread.started","thread_id":"<uuid>"}` on stdout; older codex
# printed a `session id: <uuid>` text line. Both are canonical per version.
_SID_RE = re.compile(r"session id: ([0-9a-f-]+)")


def _parse_session_id(stdout: str) -> str | None:
    for line in stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict) and event.get("thread_id"):
            return str(event["thread_id"])
    hits = _SID_RE.findall(stdout)
    return hits[-1] if hits else None


def _resolve_rollout(session_id: str) -> Path:
    home = os.path.expanduser("~/.codex/sessions")
    hits = glob.glob(f"{home}/**/rollout-*{session_id}*.jsonl", recursive=True)
    if not hits:
        raise SystemExit(f"codex-gen: no rollout jsonl for session {session_id!r} under {home}")
    hits.sort(key=os.path.getmtime, reverse=True)
    return Path(hits[0])


def _collect_inline_results(rollout: Path) -> list[str]:
    results: list[str] = []
    terminal_errors: list[str] = []
    with rollout.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            payload = record.get("payload", {}) or {}
            if payload.get("type") not in _RESULT_TYPES:
                continue
            status = payload.get("status")
            result = payload.get("result")
            # Codex Desktop 0.142.5 can emit a complete inline PNG while both
            # canonical records still say `generating`. The inline payload is
            # authoritative here; _decode_png validates it before publication.
            if result:
                results.append(result)
            elif status not in (None, "completed", "generating"):
                terminal_errors.append(str(status))
    if not results and terminal_errors:
        raise SystemExit(
            f"codex-gen: image_gen call ended with status={terminal_errors[-1]!r} in {rollout}"
        )
    return results


def _decode_png(b64: str, dest: Path) -> None:
    raw = base64.b64decode(b64)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(raw)
    verify_png(dest)


def _build_prompt(user_prompt: str) -> str:
    return (
        "image_gen 도구를 정확히 1번 호출해서 다음 프롬프트의 이미지 1장만 생성해줘.\n"
        "파일 저장·셸 명령·코드 작성·경로 보고 전부 금지. 생성만 하고 끝.\n\n"
        "프롬프트:\n"
        f"{user_prompt}\n"
    )


class CodexProvider:
    """Generate one image through codex `image_gen`."""

    name = "codex"

    def __init__(self, *, keep_session: bool = False) -> None:
        self.keep_session = keep_session

    def generate(self, request: GenRequest, workdir: Path) -> ProviderRun:
        gen_dir = os.path.expanduser("~/.codex/generated_images")
        codex_executable = shutil.which("codex") or "codex"
        cmd = [
            codex_executable,
            "exec",
            "--json",
            # The generator is a sealed one-shot image task. User/project plugin
            # configuration is unrelated and can trigger network syncs before
            # sampling, obscuring the real image-generation error. Authentication
            # is still loaded from CODEX_HOME by Codex with this flag.
            "--ignore-user-config",
            "--sandbox",
            "workspace-write",
            "--skip-git-repo-check",
            "--color",
            "never",
            "--add-dir",
            gen_dir,
            "-C",
            str(workdir),
        ]
        if request.model:
            cmd += ["--model", request.model]
        for ref in request.refs:
            cmd += ["-i", str(Path(ref).expanduser().resolve())]
        cmd += ["-", ]

        prompt = _build_prompt(request.prompt)
        started = time.monotonic()
        # Windows Korean locales default to cp949 for text pipes; sprite prompts
        # legitimately contain Unicode punctuation and multilingual descriptions.
        # Force UTF-8 so the provider receives the exact prompt on every locale.
        completed = subprocess.run(
            cmd,
            input=prompt,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        elapsed = time.monotonic() - started
        stdout = completed.stdout or ""
        if completed.returncode != 0:
            stderr = (completed.stderr or "").strip()
            lowered = stderr.lower()
            if ("os error 10013" in lowered
                    or "failed to connect to api.openai.com" in lowered
                    or "could not connect to server" in lowered):
                raise SystemExit(
                    "codex-gen: OpenAI network access is blocked for the generation server. "
                    "Restart serve_curation.py outside the restricted sandbox, then retry."
                )
            tail = stderr.splitlines()[-20:]
            raise SystemExit(
                f"codex-gen: codex exec exited {completed.returncode}\n" + "\n".join(tail)
            )

        session_id = _parse_session_id(stdout)
        if not session_id:
            raise SystemExit(
                "codex-gen: no thread/session id in codex stdout — image_gen was not reached.\n"
                "  check `codex login status` and `--sandbox workspace-write`."
            )
        rollout = _resolve_rollout(session_id)
        results = _collect_inline_results(rollout)
        if not results:
            raise SystemExit(
                f"codex-gen: no {' / '.join(_RESULT_TYPES)} inline result in {rollout}\n"
                "  image_gen may not have been called, or codex changed its session format."
            )
        _decode_png(results[-1], request.raw)

        if not self.keep_session:
            try:
                rollout.unlink()
            except OSError:
                pass

        return ProviderRun(
            provider=self.name,
            elapsed_seconds=elapsed,
            model=request.model,
            session_id=session_id,
            extra={"inline_results": len(results), "rollout_cleaned": not self.keep_session},
        )
