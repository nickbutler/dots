---
name: spec-from-code
description: Reverse-engineer a structured spec set (epics, features, Gherkin BDD acceptance criteria) from an existing codebase and its documentation. Use this skill whenever the user wants to generate specs, EPICS.md, EPIC.md, feature files, user stories, or BDD/Gherkin acceptance criteria from existing code; whenever they mention extracting specifications, building a specs folder, documenting features from code, or setting up a BDD spec structure; and whenever they refer to PLAN.md, ARCHITECTURE.md, or step_definitions in the context of writing specs. Trigger this skill even when the user does not explicitly say "spec from code" — phrases like "document what we have", "write user stories for the existing system", "set up Gherkin scenarios for our features", or "create a specs folder" should all trigger it.
---

# Spec from code

Reverse-engineer a structured spec set from an existing codebase and its documentation. Produce epics, feature files with Gherkin BDD acceptance criteria, and a tracked list of gaps where behaviour cannot be confirmed from the code.

## When to use this skill

- The user wants to generate specs, user stories, or BDD scenarios from an existing codebase
- The user has `PLAN.md`, `ARCHITECTURE.md`, or similar documentation and wants to extend it with structured specs
- The user has an existing `step_definitions/` library and wants Gherkin specs that use it
- The user asks for "spec folder", "EPICS.md", "EPIC.md", "feature files", or similar artefacts

## When NOT to use this skill

- The user wants to write specs for a system that does not yet exist — that's forward-spec work, not reverse-engineering
- The user wants architectural documentation rather than behavioural specs — use the existing `ARCHITECTURE.md` pattern instead
- The user wants API documentation — different artefact, different tooling

## Core principles

**Confirmed-only.** Only include behaviour traceable to source code, existing docs, or tests. Do not infer. Do not extrapolate. Speculative content goes to `GAPS.md`, not into specs.

**Pilot first, scale second.** Always start with one representative epic end-to-end before generating the rest. The pilot establishes the format; subsequent epics follow the pattern. Override only if the user explicitly asks for full coverage in one pass.

**Stop at checkpoints.** This workflow has natural decision points (epic selection, scaffold, feature enumeration, first feature). Stop at each and confirm with the user before proceeding. Compounding a wrong assumption across many files is expensive; a one-sentence confirmation is cheap.

**Existing step library is canonical.** When `step_definitions/` exists, use its steps verbatim wherever possible. Propose new steps in markdown for review; never modify the step library directly.

## Inputs to locate before starting

Read in this order, and report which are missing:

1. `PLAN.md` (or `ROADMAP.md`) — current direction and intent
2. `ARCHITECTURE.md` (or `docs/architecture.md`) — system structure
3. `step_definitions/` (or `features/step_definitions/`, `tests/steps/`) — Gherkin step library
4. `CLAUDE.md` / `AGENTS.md` — project conventions, if present
5. The codebase itself — source of truth

If `PLAN.md` and `ARCHITECTURE.md` are both missing, ask the user before proceeding. Specs derived from code alone, without intent docs, are technically possible but tend to capture *what* without *why*.

## Output structure

```
specs/
├── EPICS.md                           # top-level index
├── GAPS.md                            # unconfirmed items, by epic
├── STEP_DEFINITIONS_PROPOSED.md      # proposed new steps for review
└── <epic-slug>/
    ├── EPIC.md
    └── features/
        ├── <feature-slug>.md
        └── ...
```

Use `kebab-case` for slugs. Slug from the name, not a number.

## Workflow

### 1. Reconnaissance

Read the input documents. Build a mental map of the codebase using repomap, directory listing, or outline-mode reading — do not load full files speculatively. Identify the major user-facing capabilities, the typical layering, and the existing step vocabulary.

Output: a short report containing what you found, 2-3 candidate pilot epics with one-line descriptions, and your recommended choice with reasoning.

Choose the pilot based on:
- **Bounded and self-contained** — clear edges, minimal cross-cutting concerns
- **Representative** — exercises the patterns used across the broader system
- **Medium complexity** — not the trivial CRUD area, not the most tangled

**Stop here. Wait for the user to confirm the pilot epic.**

### 2. Scaffold

Create the directory structure and stub files. See `references/templates/` for the exact format of each file.

- `specs/EPICS.md` — begins with a short plain-English description of the product (1-2 sentences: what it does and for whom), then the pilot epic and candidates. Epic descriptions must be non-technical: no class names, file paths, or module references. Describe what the epic delivers to a user, not where it lives in the codebase.
- `specs/GAPS.md` — empty structure
- `specs/STEP_DEFINITIONS_PROPOSED.md` — empty structure
- `specs/<pilot-epic-slug>/EPIC.md` — stub with sections to be filled
- `specs/<pilot-epic-slug>/features/` — empty directory

**Stop. Confirm the structure looks right before populating.**

### 3. Feature enumeration

List the features within the pilot epic, one line each, based on code evidence. Each item must reference at least one file path where the feature is implemented.

**Stop. Confirm the feature list before generating any feature files.**

### 4. First feature

Generate one feature file in full, following the format in `references/templates/feature.md.template`. Apply the Confirmed-only rule strictly. Where step phrases don't match the existing library, add them to `STEP_DEFINITIONS_PROPOSED.md`.

**Stop. Get explicit feedback on the first feature before applying the format to the rest.** The pilot's pilot is the first feature — format adjustments are cheap here, expensive later.

### 5. Remaining features

Once the format is confirmed, generate the rest of the features in the pilot epic. Maintain cross-feature consistency: shared terms should match, repeated background steps should be lifted into the epic's key concepts, naming should be uniform.

### 6. Finalise

Complete `EPIC.md` (summary, scope, key concepts, architecture notes). Update `EPICS.md` with final wording. Review `GAPS.md` and `STEP_DEFINITIONS_PROPOSED.md` for completeness.

### 7. Report

Summarise:
- File tree created
- One-paragraph summary of what's covered and what's in GAPS
- Number of proposed new step definitions and rationale categories
- Patterns or inconsistencies noticed in the codebase that may warrant separate discussion (flag, do not fix)

Do not proceed beyond the pilot epic without explicit instruction.

## Confirmed vs gap — strict rules

A spec item is **Confirmed** if at least one of:

1. The behaviour is implemented in source code you have read
2. The behaviour is described in `PLAN.md` or `ARCHITECTURE.md`
3. The behaviour is exercised by an existing test
4. The behaviour is enforced by a type signature, schema, or validation rule you have inspected

For UI flows specifically, confirmation requires evidence of: the route handler, the rendering, the form/inputs, and the success/failure path. Partial evidence → GAPS with what's known and what's missing.

If you find yourself writing "the system probably…" or "this most likely…" — stop. That sentence belongs in `GAPS.md`, not in a spec file.

## Step definitions handling

Read `step_definitions/` thoroughly before writing Gherkin. Use existing steps verbatim where possible. Write idiomatic, readable scenarios — do not contort phrasing to fit the existing library at the cost of clarity.

When a scenario requires a step that doesn't exist:

1. Write the natural Gherkin phrase in the scenario
2. Add an entry to `STEP_DEFINITIONS_PROPOSED.md` following the template
3. Note whether the step is reusable across features or specific to this one

Do not modify the `step_definitions/` directory. All proposed additions go in the markdown file for review.

## Output formats

See `references/templates/`:

- `epics.md.template` — top-level index
- `epic.md.template` — per-epic summary
- `feature.md.template` — feature with user story, Gherkin, technical notes
- `gaps.md.template` — gap log structure
- `step-definitions-proposed.md.template` — proposed step format

Read the relevant template immediately before generating each file. Do not load all templates upfront — use them just-in-time to keep context lean.

## Constraints

- **Read economically.** Use repomap or outline-mode reading by default. Open full files only when their content is needed.
- **No invention.** Speculation goes to GAPS, never to specs.
- **No new step definitions in code.** All proposals go to the markdown file.
- **Match existing tone.** Read `PLAN.md` and `ARCHITECTURE.md` for voice; specs should sit alongside them naturally.
- **Cross-reference, don't duplicate.** Facts already in `ARCHITECTURE.md` get linked, not restated.
- **Do not modify** `PLAN.md`, `ARCHITECTURE.md`, or `step_definitions/` during this task. Propose changes in the appropriate output file instead.

## Override flags

The user may explicitly override defaults:

- **"Generate all epics in one pass"** — skip the pilot mode, but still stop after the first feature of the first epic for format review
- **"Include inferred behaviour, tag inline"** — switch to Confirmed/Inferred/Gap inline tagging instead of separate GAPS.md (still write GAPS.md for truly unknown items)
- **"Skip step definition verification"** — write idiomatic Gherkin without checking against the library; still record proposed steps for later review
