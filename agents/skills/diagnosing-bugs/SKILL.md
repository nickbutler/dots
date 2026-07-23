---
name: diagnosing-bugs
description: Use when a bug is reported, a test fails unexpectedly, or observed behaviour differs from expectation and the cause is not yet proven. Triggers include "bug", "broken", "why is this failing", "doesn't work", a regression found mid-task, or any fix attempt about to be made without a reproduction. Not for failures whose cause is already demonstrated red.
---

# Diagnosing Bugs

**No fix without root cause.** A fix applied to an unproven cause is a guess wearing a diff.

## Phase 1 — build a feedback loop

This is the skill. Everything after it is mechanical.

Produce **one command** that shows the bug **red** — run it, see it fail, before proceeding. Ways to build one, in preference order:

1. Failing test reproducing the report
2. `curl`/httpie against a running instance
3. CLI invocation + expected-vs-actual diff
4. Script harness calling the suspect function directly (REPL-style — the layered architecture exists for this)
5. `git bisect run` with any of the above
6. Headless browser script (UI bugs)
7. Prod-only bugs: a trap — instrument the failure site to capture inputs, state, and environment when it next fires; the trap is the loop, and each hypothesis dictates a field it records. A workaround that silences the failure without capturing it destroys the loop
8. Human-in-the-loop script: you run it, Nick reports what he sees — last resort

Then **tighten the loop**: a 2-second deterministic loop beats a 30-second flaky one. Shrink the input to minimal, cut unneeded dependencies, pin seeds/clocks. Flaky reproduction → the flakiness is part of the bug; chase determinism first.

**Gate: no red-capable command, no Phase 2.** Phase 1 is done only when you can paste the command and its red output, already run this session.

## Phase 2 — hypotheses

Write **3–5 ranked hypotheses**. A single hypothesis is anchoring, not diagnosis.

Each must carry a falsifiable prediction: *"if this is the cause, then \<experiment\> will show \<specific observation\>"*. Can't state the prediction → it's a vibe; discard it.

- Test the cheapest decisive experiment first
- One variable per experiment — a run that changes two things proves nothing
- Debug logging gets a tag: `[DEBUG-<4-char-id>]` — cleanup is one grep
- An experiment that kills all hypotheses is progress: write 3–5 new ones from what it showed

## Phase 3 — fix

TDD applies to bugfixes. The Phase 1 loop becomes (or spawns) a failing test committed with the fix:

1. Red: test encoding the root cause fails
2. Fix the cause — not the symptom upstream of it
3. Green: loop passes; run the module's suite
4. Grep the `[DEBUG-` tag; remove all instrumentation

If the loop wasn't a test (curl, script), still write the regression test — the loop was for diagnosis, the test is for keeps.

## Escape hatch

3+ failed fix attempts → stop. The problem is architectural, not local. Say so and talk to Nick.

## Rationalizations that don't fly

- "I can see the bug, just fix it" → seen is not proven; the loop costs minutes, thrashing costs hours
- "Too hard to reproduce" → then no fix can be verified either; reproduction *is* the work
- "Production is down, no time for process" → systematic is faster than thrashing, especially now
- "I'll remove the print statements later" → tag them or lose them

Catch yourself thinking *"quick fix for now"*, *"one more attempt"*, *"probably"*, *"should work now"* → stop, return to the current phase's gate.

## Post-mortem

One sentence to Nick after green: what would have prevented this class of bug — a test at a seam, a type, validation at a boundary? Suggest; don't implement unasked.
