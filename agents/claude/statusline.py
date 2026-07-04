#!/usr/bin/env python3
"""Claude Code status line.

Reads the status-line JSON payload on stdin and prints a single line:

    Fable 5 · worktree-name/branch-name · [ctx ███████░░░░░ 61% 608.9k/1M] · [5h █████░░░░░░░ 38% 52m] · [7d ██░░░░░░░░░░ 16% 5d19h] · $207.95 · ~/code/projects/sapphire

- model:  model.display_name (first)
- branch: worktree-name/branch-name; worktree prefix omitted when not in a worktree
          session. Branch resolved via worktree.branch → workspace.git_worktree →
          git symbolic-ref fallback.
- ctx:    bracketed context-window bar + percent + used/total tokens.
- 5h/7d:  bracketed rate-limit windows with time remaining; each omitted when absent.
- cost:   session total (cost.total_cost_usd); omitted when absent or zero.
- cwd:    current directory with ~ abbreviation (last).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time

BAR_WIDTH = 12

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"


def bar(pct: float) -> str:
    filled = max(0, min(BAR_WIDTH, round(pct / 100 * BAR_WIDTH)))
    color = GREEN if pct < 50 else YELLOW if pct < 80 else RED
    return f"{color}{'█' * filled}{DIM}{'░' * (BAR_WIDTH - filled)}{RESET}"


def until(resets_at: float | None) -> str:
    """Compact time remaining until a unix-epoch reset, e.g. '3h12m'."""
    if not resets_at:
        return ""
    secs = int(resets_at - time.time())
    if secs <= 0:
        return "0m"
    days, rem = divmod(secs, 86400)
    hours, rem = divmod(rem, 3600)
    mins = rem // 60
    if days:
        return f"{days}d{hours}h"
    if hours:
        return f"{hours}h{mins}m"
    return f"{mins}m"


def compact_tokens(n: int) -> str:
    """Format a token count compactly: 132000 → '132k', 1500000 → '1.5M'."""
    if n >= 1_000_000:
        val = n / 1_000_000
        return f"{val:.1f}M" if val % 1 else f"{int(val)}M"
    if n >= 1_000:
        val = n / 1_000
        return f"{val:.1f}k" if val % 1 else f"{int(val)}k"
    return str(n)


def compact_path(path: str) -> str:
    """Replace $HOME prefix with ~."""
    home = os.path.expanduser("~")
    if path.startswith(home):
        return "~" + path[len(home):]
    return path


def git_branch(cwd: str) -> str | None:
    """Return current branch short name, or None if not in a git repo."""
    try:
        result = subprocess.run(
            ["git", "-C", cwd, "--no-optional-locks", "symbolic-ref", "--short", "HEAD"],
            capture_output=True,
            text=True,
            timeout=2,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        pass
    return None


def ctx_segment(ctx: dict) -> str | None:
    """Return '[ctx <bar> <pct>% <used>/<total>]' or None if no data."""
    pct = ctx.get("used_percentage")
    if pct is None:
        return None
    used = ctx.get("total_input_tokens")
    total = ctx.get("context_window_size")
    tokens_part = ""
    if used is not None and total:
        tokens_part = f" {DIM}{compact_tokens(int(used))}/{compact_tokens(int(total))}{RESET}"
    return f"{DIM}[{RESET}ctx {bar(float(pct))} {float(pct):.0f}%{tokens_part}{DIM}]{RESET}"


def rate_segment(label: str, window: dict) -> str | None:
    """Return '[<label> <bar> <pct>% <time-remaining>]' or None if no data."""
    pct = window.get("used_percentage")
    if pct is None:
        return None
    time_str = until(window.get("resets_at"))
    time_part = f" {DIM}{time_str}{RESET}" if time_str else ""
    return f"{DIM}[{RESET}{label} {bar(float(pct))} {float(pct):.0f}%{time_part}{DIM}]{RESET}"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        data = {}

    sep = f" {DIM}·{RESET} "
    parts: list[str] = []

    # 1. Model
    model = (data.get("model") or {}).get("display_name", "Claude")
    parts.append(f"{BOLD}{CYAN}{model}{RESET}")

    # 2. worktree-name/branch-name (or just branch-name)
    cwd = data.get("cwd") or (data.get("workspace") or {}).get("current_dir", "")
    worktree = data.get("worktree") or {}
    worktree_name = worktree.get("name")
    branch = worktree.get("branch")
    if not branch:
        branch = (data.get("workspace") or {}).get("git_worktree")
    if not branch and cwd:
        branch = git_branch(cwd)

    if worktree_name or branch:
        if worktree_name and branch:
            location = f"{worktree_name}/{branch}"
        else:
            location = worktree_name or branch
        parts.append(f"{BOLD}{location}{RESET}")

    # 3. Context window
    seg = ctx_segment(data.get("context_window") or {})
    if seg:
        parts.append(seg)

    # 4 & 5. Rate limits
    rate = data.get("rate_limits") or {}
    for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
        seg = rate_segment(label, rate.get(key) or {})
        if seg:
            parts.append(seg)

    # 6. Cost
    cost = (data.get("cost") or {}).get("total_cost_usd")
    if isinstance(cost, (int, float)) and cost > 0:
        parts.append(f"${cost:.2f}")

    # 7. cwd
    if cwd:
        parts.append(f"{DIM}{compact_path(cwd)}{RESET}")

    sys.stdout.write(sep.join(parts))


if __name__ == "__main__":
    main()
