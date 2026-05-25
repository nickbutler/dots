---
name: spec-sync
description: Update an existing spec set to reflect the current state of the codebase. Use this skill whenever the user wants to sync, refresh, update, reconcile, or refresh specs against code; whenever they mention spec drift, stale specs, outdated EPICS.md or EPIC.md or feature files, or want to detect what changed since the last sync; and whenever they refer to keeping specs current with the codebase. Trigger this skill even when the user does not explicitly say "spec-sync" — phrases like "check if our specs are still accurate", "specs are out of date", "update the user stories for the new code", "what's drifted in our specs", or "refresh the specs folder" should all trigger it. This is the companion to spec-from-code; use this when a specs/ folder already exists, use spec-from-code when starting fresh.

---

# Spec sync

Reconcile an existing spec set with the current state of the codebase. Detect drift, surface deprecations, identify uncovered code, resolve previously-recorded gaps, and apply updates conservatively.

## When to use this skill

- A `specs/` folder already exists from a previous spec-from-code run or earlier sync
- The user wants to refresh specs after a period of development
- The user asks about spec drift, staleness, or accuracy
- The user wants to know what's changed since the specs were last updated

## When NOT to use this skill

- No `specs/` folder exists yet — use **spec-from-code** instead
- The user wants to write specs for code that doesn't exist yet (forward-spec work)
- The user wants to rewrite specs from scratch — use **spec-from-code** with explicit instruction to overwrite

## Core principles

**Specs are lightly human-edited.** Assume human curation has occurred since last sync — clarifying comments, resolved gaps, refined scenario phrasing. Preserve human edits wherever the underlying behaviour hasn't changed. Don't rewrite cosmetic content just because it differs from what the agent would generate today.

**Behaviour change drives spec change.** A refactor that preserves behaviour should not trigger a scenario update. A change to validation rules, error handling, or user-visible flow should. When uncertain whether a code change is behaviour-affecting, ask the user.

**Surface, don't decide.** When intent is ambiguous (intentional removal or accidental regression? renamed feature or new feature? deliberate scope narrowing or bug?), prompt the user rather than guessing. A short clarification is cheaper than a confident wrong update.

**Never silently delete.** Removed features get archived, not deleted. Resolved gaps get moved to the relevant spec, not just removed from `GAPS.md`. The git history plus an archive folder is the audit trail.

**Changes reviewed via git.** Apply changes directly to files. The user reviews via git diff and commits, amends, or reverts as they choose. No separate proposal stage.

## Workflow

### 1. Inventory and change detection

Read the existing spec set in full — it's compact by design, and you need the complete picture. Build an internal map of: epics, features within each, current gap entries, current proposed step definitions.

Determine what's changed since last sync. In order of preference:

1. **Git-based**: diff the codebase between the last commit that touched `specs/` and `HEAD`. This is the cleanest signal of what has changed in the implementation since specs were last current.
2. **Sync marker**: if `specs/.last_sync` exists with a commit SHA, diff from there to `HEAD` instead.
3. **Fallback**: compare file modification times between `specs/` and source directories, treating source files newer than the most recent spec edit as candidates for review.

Report the detection method used and what it surfaced. This goes in the final `SYNC_REPORT.md` regardless of outcome.

### 2. Categorise

For every spec feature, assign one of:

- **Unchanged** — code referenced by the feature has not changed
- **Drift candidate** — code has changed in a way that may affect behaviour; needs review
- **Refactor only** — code changed but behaviour appears preserved (e.g. file renames, internal restructuring without signature changes)
- **Deprecated candidate** — code referenced by the feature no longer exists or no longer behaves as a feature

For new or significantly-changed code with no matching feature:

- **Uncovered** — code exists but no spec describes it

For existing `GAPS.md` entries:

- **Resolved** — code or docs now answer the gap
- **Still open** — gap remains
- **Obsolete** — the area the gap referenced is no longer relevant

For `STEP_DEFINITIONS_PROPOSED.md` entries:

- **Satisfied** — the step now exists in the `step_definitions/` library
- **Still pending** — no matching step exists yet
- **Obsolete** — the scenario referencing this step has been removed

**Stop here and report the categorisation summary to the user.** Numbers only at this stage — full detail comes in the report. This is the natural point to confirm scope before applying changes.

### 3. Apply changes

For each category, in this order:

**Refactor-only items**: update technical notes in feature files (path changes, type renames) without touching scenarios. Cosmetic preservation matters — don't rewrite the scenario phrasing the human edited last week.

**Drift candidates**: for each, determine whether scenarios need updating. If the change is unambiguous (e.g. new required field, removed validation rule), update the relevant scenarios. If ambiguous, **prompt the user** with the specific question: "The `process_payment` function now requires `idempotency_key` — is this an intentional contract change, or a temporary internal field?"

**Uncovered code**: create feature files following the existing format in this spec set. Use `references/templates/feature.md.template` for structure. Apply the Confirmed-only rule from spec-from-code — gaps go to `GAPS.md`.

**Deprecated candidates**: do not delete. Move to `specs/<epic>/archived/<feature-slug>.md` with a deprecation header noting the date, the last commit where the feature existed, and (if known) why it was removed. If you don't know why, prompt the user.

**Resolved gaps**: move the content into the relevant spec file (feature, epic, or new gap area), then remove from `GAPS.md`. Reference the spec file in a brief "resolved" note at the bottom of `GAPS.md` so the history isn't lost.

**Satisfied step proposals**: remove from `STEP_DEFINITIONS_PROPOSED.md`. If the satisfaction is uncertain (a step with similar but not identical phrasing exists), prompt the user.

**Obsolete entries** (gaps or step proposals): remove with a one-line note in the relevant file's history section if one exists.

### 4. Update cross-cutting files

- `EPICS.md`: update the candidate epics list if new uncovered areas suggest new epics
- `EPIC.md` (per affected epic): refresh the features list, architecture notes if module paths changed
- `GAPS.md`: contains only still-open and newly-discovered gaps
- `STEP_DEFINITIONS_PROPOSED.md`: contains only still-pending and newly-proposed steps

### 5. Write SYNC_REPORT.md

Replace any previous `specs/SYNC_REPORT.md` with a fresh one for this run. Use `references/templates/sync-report.md.template`. Include:

- Detection method used
- Counts per category
- List of features changed, with one-line summary of each change
- List of clarifications requested from the user and how each was resolved
- List of patterns or inconsistencies noticed (flag, do not fix)

The report is informational, not gated — the user will already see the actual changes in git diff.

### 6. Update sync marker

Write the current HEAD commit SHA to `specs/.last_sync`. If the file doesn't exist, create it. This anchors the next sync.

### 7. Report

Brief summary to the user:
- Total files changed
- Number of clarifications requested and resolved
- Any items deferred (e.g. user said "I'll think about that one")
- Pointer to `SYNC_REPORT.md` for the full picture
- Suggestion to review via `git diff specs/` before committing

## When to prompt the user

Ask, don't guess, when:

- A behaviour change could be either intentional contract change or accidental regression
- A feature appears removed but might have been renamed or moved
- A new step in `step_definitions/` is similar to a pending proposal but not identical
- Multiple plausible mappings exist between new code and existing features
- A change spans multiple epics in a way that suggests the epic boundary may need revisiting

Bundle clarification questions when possible — one prompt with five questions is less disruptive than five separate prompts. Number them and number the answers.

Keep clarifications focused: state the specific code change, the affected spec content, and the question. Do not ask the user to re-derive context the skill already has.

## What not to do

- **Don't refactor specs cosmetically.** If a scenario reads naturally and the behaviour is unchanged, leave the phrasing alone even if you'd write it differently.
- **Don't expand scope.** Sync updates existing content and adds coverage for new code. It does not rewrite epics, restructure folders, or "improve" the spec set's organisation. That's a separate task.
- **Don't modify** `PLAN.md`, `ARCHITECTURE.md`, `step_definitions/`, or anything outside `specs/` during this task.
- **Don't auto-resolve high-stakes ambiguities.** Removed features, contract changes, and security-relevant behaviour all warrant a prompt rather than an assumption.
- **Don't delete the archive folder.** `specs/<epic>/archived/` accumulates across syncs — that's the deprecation history. Leave it alone.

## Templates

See `references/templates/`:

- `feature.md.template`, `epic.md.template`, `epics.md.template`, `gaps.md.template`, `step-definitions-proposed.md.template` — same templates as spec-from-code, used when creating new files for uncovered code
- `sync-report.md.template` — sync-specific report format

Read each template only when you need it.
