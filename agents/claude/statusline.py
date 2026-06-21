#!/usr/bin/env python3
"""Claude Code status line.

Reads the status-line JSON payload on stdin and prints a single line:

    Opus 4.8 · [████████░░░░] 66% ctx · 5h [███░░░░░░░░░] 24% · 7d [████░] 41% · $0.42

- model:  model.display_name
- ctx:    context-window usage bar + percentage, from the pre-calculated
          context_window.used_percentage (matches /context).
- 5h/7d:  rate-limit window usage from rate_limits.{five_hour,seven_day}.
          Only present for Claude.ai Pro/Max after the first API response, and
          each window can be independently absent — shown only when available.
- cost:   session total cost (cost.total_cost_usd), shown when non-zero.
"""

from __future__ import annotations

import json
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
        return " 0m"
    days, rem = divmod(secs, 86400)
    hours, rem = divmod(rem, 3600)
    mins = rem // 60
    if days:
        return f" {DIM}{days}d{hours}h{RESET}"
    if hours:
        return f" {DIM}{hours}h{mins}m{RESET}"
    return f" {DIM}{mins}m{RESET}"


def gauge(pct: float, label: str, resets_at: float | None = None) -> str:
    return f"{bar(pct)} {pct:.0f}% {DIM}{label}{RESET}{until(resets_at)}"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        data = {}

    model = (data.get("model") or {}).get("display_name", "Claude")
    parts = [f"{BOLD}{CYAN}{model}{RESET}"]

    ctx_pct = (data.get("context_window") or {}).get("used_percentage")
    parts.append(gauge(float(ctx_pct or 0), "ctx"))

    rate = data.get("rate_limits") or {}
    for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
        window = rate.get(key) or {}
        pct = window.get("used_percentage")
        if pct is not None:
            parts.append(gauge(float(pct), label, window.get("resets_at")))

    cost = (data.get("cost") or {}).get("total_cost_usd")
    if isinstance(cost, (int, float)) and cost > 0:
        parts.append(f"${cost:.2f}")

    sys.stdout.write(f" {DIM}·{RESET} ".join(parts))


if __name__ == "__main__":
    main()
