#!/usr/bin/env python3
"""Claude Code status line.

Reads the status-line JSON payload on stdin and prints a single line:

    Opus 4.8 · [████████░░░░] 66% 132k/200k ctx · 5h [███░░░░░░░░░] 24% · 7d [████░] 41% · $0.42

- model:  model.display_name
- ctx:    context-window usage bar + percentage + raw tokens (used/total in
          compact "k" notation), from context_window.used_percentage,
          context_window.total_input_tokens, and context_window.context_window_size.
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


def compact_tokens(n: int) -> str:
    """Format a token count compactly: 132000 → '132k', 1500000 → '1.5M'."""
    if n >= 1_000_000:
        val = n / 1_000_000
        return f"{val:.1f}M" if val % 1 else f"{int(val)}M"
    if n >= 1_000:
        val = n / 1_000
        return f"{val:.1f}k" if val % 1 else f"{int(val)}k"
    return str(n)


def gauge(pct: float, label: str, resets_at: float | None = None, tokens: str | None = None) -> str:
    token_part = f" {DIM}{tokens}{RESET}" if tokens else ""
    return f"{bar(pct)} {pct:.0f}%{token_part} {DIM}{label}{RESET}{until(resets_at)}"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        data = {}

    model = (data.get("model") or {}).get("display_name", "Claude")
    parts = [f"{BOLD}{CYAN}{model}{RESET}"]

    ctx = data.get("context_window") or {}
    ctx_pct = ctx.get("used_percentage")
    ctx_used = ctx.get("total_input_tokens")
    ctx_total = ctx.get("context_window_size")
    tokens_str: str | None = None
    if ctx_used is not None and ctx_total:
        tokens_str = f"{compact_tokens(int(ctx_used))}/{compact_tokens(int(ctx_total))}"
    parts.append(gauge(float(ctx_pct or 0), "ctx", tokens=tokens_str))

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
