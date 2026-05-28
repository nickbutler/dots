---
name: spec
description: Create, infer, or update a structured spec set (epics, features, Gherkin BDD acceptance criteria). Three modes — invoke as /spec create (design a spec from conversation before code exists), /spec infer (reverse-engineer a spec from an existing codebase), or /spec update (reconcile existing specs with code changes). Trigger this skill even when the user does not explicitly name a mode — phrases like "let's plan what we're building" or "spec out the new feature" → create; "document what we have", "write user stories for the existing system", "create a specs folder" → infer; "specs are out of date", "sync the specs", "what's drifted" → update. When mode is ambiguous, auto-detect from context (see Mode dispatch).
---

# Spec

Generate and maintain a structured spec set: epics, feature files with Gherkin BDD acceptance criteria, and supporting artefacts.

## Mode dispatch

| Command | When to use |
|---|---|
| `/spec create` | No code yet — design a spec from a conversation or planning discussion |
| `/spec infer` | Code exists, no `specs/` folder — reverse-engineer specs from the codebase |
| `/spec update` | `specs/` folder exists — reconcile specs with code changes |

**Auto-detect when no mode is given:**
1. `specs/` folder exists → **update**
2. No `specs/`, but a codebase exists → **infer**
3. No `specs/`, no codebase → **create**
4. Ambiguous (e.g. `specs/` exists but user says "start fresh") → ask

---

## Shared: output structure

```
specs/
├── EPICS.md                          # top-level index
├── GAPS.md                           # items needing clarification (see mode notes)
├── STEP_DEFINITIONS_PROPOSED.md      # proposed new Gherkin steps
├── DESIGN_DECISIONS.md               # [create mode only] decided choices and open questions
├── SYNC_REPORT.md                    # [update mode only] report for the current sync run
└── <epic-slug>/
    ├── EPIC.md
    ├── features/
    │   └── <feature-slug>.md
    └── archived/                     # [update mode] deprecated features
        └── <feature-slug>.md
```

Use `kebab-case` slugs derived from names, not numbers.

## Shared: core disciplines

**Pilot first, scale second.** Always start with one representative epic end-to-end before generating the rest. The pilot establishes format; subsequent epics follow it. Override only with explicit instruction.

**Stop at checkpoints.** Each mode has natural decision points. Stop at each and confirm before proceeding. Compounding a wrong assumption across many files is expensive; a one-sentence confirmation is cheap.

**Existing step library is canonical.** When `step_definitions/` exists, use its steps verbatim. Propose new steps in `STEP_DEFINITIONS_PROPOSED.md`; never modify the step library directly.

**No invention.** Never add behaviour, features, or requirements that weren't confirmed (infer/update) or explicitly discussed (create). Speculation goes to `GAPS.md` or `DESIGN_DECISIONS.md`.

## Shared: step definitions handling

Read `step_definitions/` thoroughly before writing Gherkin. Use existing steps verbatim where possible. Write idiomatic, readable scenarios — don't contort phrasing to fit the library at the cost of clarity.

When a scenario requires a step that doesn't exist:
1. Write the natural Gherkin phrase in the scenario
2. Add an entry to `STEP_DEFINITIONS_PROPOSED.md` using the template
3. Note whether the step is reusable or feature-specific

If no `step_definitions/` exists yet (common in create mode), write idiomatic Gherkin freely.

## Shared: templates

All templates are in `references/templates/`. Read each one just-in-time — only when you're about to generate that file. Do not load all templates upfront.

| Template | Used by |
|---|---|
| `epics.md.template` | all modes |
| `epic.md.template` | all modes |
| `feature.md.template` | all modes |
| `gaps.md.template` | all modes |
| `step-definitions-proposed.md.template` | all modes |
| `design-decisions.md.template` | create mode |
| `sync-report.md.template` | update mode |

---

## Mode: create

Design a spec set from a planning conversation, before any code exists. Specs here are **prescriptive** (defining intent) rather than descriptive (observing behaviour).

### When to use

- Planning a new project or feature before writing code
- The design discussion is in this conversation and should be captured as structured specs
- Neither code nor a `specs/` folder exists yet

### When NOT to use

- Code already exists → use **infer**
- `specs/` already exists → use **update**

### Additional principles

**Vocabulary first.** Establish domain language before writing scenarios. The terms defined here become the terms used in code — consistency from spec to implementation prevents drift before it starts.

**Open questions are first-class.** Design gaps are decisions deferred, not failures. Track them in `DESIGN_DECISIONS.md` with enough context that they can be answered when implementation begins. Papering over uncertainty produces specs that mislead.

**MVP scope explicit.** Distinguish what's in scope for the first iteration from what's a later phase.

**Scenarios are implementation-agnostic.** Write acceptance criteria at the behaviour level. Save implementation hints for `Technical notes`; don't over-specify approach in Gherkin.

### GAPS.md in create mode

Gaps here are spec-level ambiguities — the design discussion wasn't specific enough to write a complete scenario. Unlike infer mode, there's no code to inspect; these require further design work. Use "What was discussed" in place of "Where you looked".

### Workflow

#### 1. Elicitation summary

Synthesise from the conversation:

- **Product/feature**: what it does and for whom (one sentence)
- **Actors**: who uses the system and in what roles
- **Core goals**: outcomes actors are trying to achieve (3–6 items)
- **Constraints**: technical, legal, timeline, or product constraints explicitly mentioned
- **Non-functional requirements**: only what was stated
- **Domain vocabulary**: key terms and their definitions as used in the discussion
- **Scope signals**: anything explicitly said to be in or out of scope

Flag any category with insufficient signal — those become initial Open entries in `DESIGN_DECISIONS.md`.

**Stop. Let the user correct or extend the elicitation summary before proceeding.**

#### 2. Epic identification

Present 3–6 candidate epics with one-line user-facing descriptions. Recommend a pilot epic (bounded, representative, medium complexity). Note which epics are MVP vs. later phase.

**Stop. Confirm epic list and pilot choice.**

#### 3. Scaffold

Create directory structure and stub files: `EPICS.md`, `DESIGN_DECISIONS.md` (populate with decisions and open questions surfaced so far), `GAPS.md` (empty structure), `STEP_DEFINITIONS_PROPOSED.md` (empty), `<pilot-epic-slug>/EPIC.md` (stub), `<pilot-epic-slug>/features/` (empty).

**Stop. Confirm structure before populating.**

#### 4. Feature enumeration

List features within the pilot epic, one line each. Each must state the user capability, the actor, and whether it's MVP or later.

**Stop. Confirm feature list.**

#### 5. First feature

Generate one feature file in full, with these adaptations:
- `Technical notes` → populate what's known; use `TBD: <question>` for undecided implementation details; each TBD should also appear in `DESIGN_DECISIONS.md` (Open)
- `Notes on confirmation` → rename to `Notes on scope`; flag scenarios that are inferred from discussion (not explicitly stated), edge cases not discussed, or contingent on an open decision

**Stop. Get explicit feedback before applying the format to remaining features.**

#### 6. Remaining features → Finalise → Report

Generate remaining pilot features. Complete `EPIC.md` and `EPICS.md`. Populate `DESIGN_DECISIONS.md` with all choices and open questions from the session. Report: file tree, domain vocabulary established, count of open decisions, count of spec gaps, recommended next step.

---

## Mode: infer

Reverse-engineer a structured spec set from an existing codebase and its documentation. Specs here are **descriptive** (observing confirmed behaviour).

### When to use

- Code exists but no `specs/` folder
- Generating specs, user stories, or Gherkin scenarios from existing source code
- Setting up a BDD spec structure for a working system

### When NOT to use

- No code exists yet → use **create**
- `specs/` already exists → use **update**

### Additional principles

**Confirmed-only.** Only include behaviour traceable to source code, existing docs, or tests. Do not infer. Do not extrapolate. Speculative content goes to `GAPS.md`.

### Confirmed vs gap — strict rules

A spec item is **confirmed** if at least one of:
1. The behaviour is implemented in source code you have read
2. The behaviour is described in `PLAN.md` or `ARCHITECTURE.md`
3. The behaviour is exercised by an existing test
4. The behaviour is enforced by a type signature, schema, or validation rule you have inspected

For UI flows, confirmation requires evidence of: the route handler, the rendering, the form/inputs, and the success/failure path. Partial evidence → GAPS.

If you find yourself writing "the system probably…" or "this most likely…" — stop. That sentence belongs in `GAPS.md`.

### Inputs to locate

Read in this order, report which are missing:

1. `PLAN.md` (or `ROADMAP.md`)
2. `ARCHITECTURE.md` (or `docs/architecture.md`)
3. `step_definitions/` (or `features/step_definitions/`, `tests/steps/`)
4. `CLAUDE.md` / `AGENTS.md`
5. The codebase itself

If both `PLAN.md` and `ARCHITECTURE.md` are missing, ask before proceeding.

### Workflow

#### 1. Reconnaissance

Read input documents. Build a map of the codebase (directory listing, outline-mode reading — don't load full files speculatively). Identify major user-facing capabilities, layering, and the existing step vocabulary.

Report: what you found, 2–3 candidate pilot epics with one-line descriptions, recommended choice with reasoning.

Pilot selection criteria: bounded and self-contained, representative of broader patterns, medium complexity.

**Stop. Wait for the user to confirm the pilot epic.**

#### 2. Scaffold

Create directory structure and stub files: `EPICS.md`, `GAPS.md`, `STEP_DEFINITIONS_PROPOSED.md`, `<pilot-epic-slug>/EPIC.md` (stub), `<pilot-epic-slug>/features/` (empty). `EPICS.md` begins with a plain-English product description (1–2 sentences, no class names or file paths).

**Stop. Confirm structure before populating.**

#### 3. Feature enumeration

List features within the pilot epic, one line each. Each must reference at least one file path where the feature is implemented.

**Stop. Confirm feature list.**

#### 4. First feature

Generate one feature file in full. Apply the confirmed-only rule strictly. Add unconfirmed steps to `STEP_DEFINITIONS_PROPOSED.md`.

**Stop. Get explicit feedback on the first feature before applying the format to the rest.**

#### 5. Remaining features → Finalise → Report

Generate remaining pilot features. Complete `EPIC.md` and `EPICS.md`. Review `GAPS.md` and `STEP_DEFINITIONS_PROPOSED.md`. Report: file tree, what's covered and what's in GAPS, number of proposed step definitions, patterns or inconsistencies noticed (flag, do not fix).

Do not proceed beyond the pilot epic without explicit instruction.

---

## Mode: update

Reconcile an existing spec set with the current state of the codebase. Detect drift, surface deprecations, identify uncovered code.

### When to use

- A `specs/` folder already exists from a previous run or sync
- Refreshing specs after a period of development
- Detecting spec drift or staleness

### When NOT to use

- No `specs/` folder exists → use **infer** (or **create** if no code either)
- Rewriting specs from scratch → use **infer** with explicit instruction to overwrite

### Additional principles

**Specs are lightly human-edited.** Assume human curation has occurred since last sync. Preserve human edits wherever the underlying behaviour hasn't changed.

**Behaviour change drives spec change.** A refactor that preserves behaviour should not trigger a scenario update.

**Surface, don't decide.** When intent is ambiguous (intentional removal or accidental regression?), prompt the user rather than guessing.

**Never silently delete.** Removed features get archived to `specs/<epic>/archived/`, not deleted.

**Changes reviewed via git.** Apply changes directly to files. The user reviews via `git diff specs/` and commits, amends, or reverts as they choose.

### Change detection (in preference order)

1. **Git-based**: diff between the last commit touching `specs/` and `HEAD`
2. **Sync marker**: if `specs/.last_sync` exists with a commit SHA, diff from there to `HEAD`
3. **Fallback**: compare file modification times between `specs/` and source directories

Report the detection method used. This appears in `SYNC_REPORT.md`.

### Categorisation

For every spec feature, assign one of:
- **Unchanged** — referenced code has not changed
- **Drift candidate** — code changed in a way that may affect behaviour
- **Refactor only** — code changed but behaviour appears preserved
- **Deprecated candidate** — referenced code no longer exists

For new or significantly-changed code with no matching feature: **Uncovered**

For `GAPS.md` entries: **Resolved**, **Still open**, or **Obsolete**

For `STEP_DEFINITIONS_PROPOSED.md` entries: **Satisfied**, **Still pending**, or **Obsolete**

**Stop. Report the categorisation summary (numbers only). Confirm scope before applying changes.**

### Applying changes

In order:
- **Refactor-only**: update technical notes (paths, type names) without touching scenarios
- **Drift candidates**: update unambiguous changes; prompt the user on ambiguous ones
- **Uncovered**: create feature files using `references/templates/feature.md.template`; apply confirmed-only rule
- **Deprecated**: move to `specs/<epic>/archived/<feature-slug>.md` with deprecation header (date, last commit, reason if known — prompt if unknown)
- **Resolved gaps**: move content into the relevant spec file; add a brief "resolved" note in `GAPS.md`
- **Satisfied proposals**: remove from `STEP_DEFINITIONS_PROPOSED.md`
- **Obsolete entries**: remove with a one-line note in a history section if one exists

### Update cross-cutting files

- `EPICS.md`: add candidate epics if new uncovered areas suggest them
- `EPIC.md` (per affected epic): refresh feature list, architecture notes
- `GAPS.md`: open and newly-discovered gaps only
- `STEP_DEFINITIONS_PROPOSED.md`: pending and newly-proposed steps only

### Finalise

Write `specs/SYNC_REPORT.md` using `references/templates/sync-report.md.template`. Write current HEAD SHA to `specs/.last_sync`.

Report: total files changed, clarifications requested and resolved, items deferred, pointer to `SYNC_REPORT.md`, suggestion to review via `git diff specs/`.

### When to prompt the user

Bundle clarification questions when possible. Ask (don't guess) when:
- A behaviour change could be intentional contract change or accidental regression
- A feature appears removed but might have been renamed
- A new step in the library is similar to a pending proposal but not identical
- Multiple plausible mappings exist between new code and existing features

---

## Override flags (all modes)

- **"Generate all epics in one pass"** — skip pilot mode; still stop after the first feature for format review
- **"Include inferred behaviour, tag inline"** — (infer/update) switch to Confirmed/Inferred/Gap inline tagging instead of separate GAPS.md
- **"Skip step definition verification"** — write idiomatic Gherkin without checking against the library; still record proposed steps
