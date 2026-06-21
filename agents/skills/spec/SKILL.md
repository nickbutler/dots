---
name: spec
description: Create, infer, or update a structured spec set (features, Gherkin BDD acceptance criteria, executable .feature files). Three modes — invoke as /spec create (design a spec from conversation before code exists), /spec infer (reverse-engineer a spec from an existing codebase), or /spec update (reconcile existing specs with code changes). Each feature produces a paired .md (user story, context, technical notes) and .feature (executable Gherkin for pytest-bdd or Cucumber). Trigger this skill even when the user does not explicitly name a mode — phrases like "let's plan what we're building" or "spec out the new feature" → create; "document what we have", "write user stories for the existing system", "create a specs folder" → infer; "specs are out of date", "sync the specs", "what's drifted" → update. When mode is ambiguous, auto-detect from context (see Mode dispatch).
---

# Spec

Generate and maintain a structured spec set: a flat list of feature files with Gherkin BDD acceptance criteria and supporting artefacts.

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
├── INDEX.md                          # flat feature list with status
├── ARCHITECTURE.md                   # cross-cutting technical design (current state)
├── DATA_MODEL.md                     # [optional] entity definitions, fields, types, persistence
├── DESIGN_DECISIONS.md               # ADR log — decisions made and considerations weighed
├── GAPS.md                           # items needing clarification
├── SYNC_REPORT.md                    # [update mode only] report for the current sync run
├── features/
│   ├── <feature-slug>.md             # user story, context, technical notes, status
│   └── <feature-slug>.feature        # executable Gherkin (pytest-bdd / Cucumber)
└── archived/                         # [update mode] deprecated features
    ├── <feature-slug>.md
    └── <feature-slug>.feature
```

**`ARCHITECTURE.md`** documents the current technical design: design principles, constraints, key abstractions, system boundaries, and module structure. It describes *what is true now* and is updated when the structure changes.

**`DATA_MODEL.md`** is optional — create it when the project has persistent or structured data worth specifying. It holds the concrete detail: entity definitions, field names, types, validation rules, and persistence notes. `ARCHITECTURE.md` keeps the conceptual domain overview; `DATA_MODEL.md` is where an implementer goes to understand the actual shape of the data.

**`DESIGN_DECISIONS.md`** is the ADR log: *why* the architecture looks the way it does. Each entry records the decision made, the alternatives considered, and the constraints or considerations that drove the choice. Entries are append-only — revise by adding a new entry, not overwriting.

Each feature is a pair of files with the same slug. The `.md` carries the human-readable context; the `.feature` carries the executable Gherkin. They are always created and archived together.

Use `kebab-case` slugs derived from names, not numbers.

## Shared: core disciplines

**Stop at checkpoints.** Each mode has natural decision points. Stop at each and confirm before proceeding. Compounding a wrong assumption across many files is expensive; a one-sentence confirmation is cheap.

**Existing step library is canonical.** When `step_definitions/` exists, use its steps verbatim. Never modify the step library directly. When a scenario requires a step that doesn't exist, write the natural Gherkin phrase and tag the scenario `@draft` — a signal that the step needs implementing before the scenario can run.

**No invention.** Never add behaviour, features, or requirements that weren't confirmed (infer/update) or explicitly discussed (create). Speculation goes to `GAPS.md` or `DESIGN_DECISIONS.md`.

## Shared: step definitions handling

Read `step_definitions/` thoroughly before writing Gherkin. Use existing steps verbatim where possible. Write idiomatic, readable scenarios — don't contort phrasing to fit the library at the cost of clarity.

When a scenario requires a step that doesn't exist, write the natural Gherkin phrase and tag the scenario `@draft`. The user removes `@draft` when they have reviewed the scenario and are satisfied the step phrasing is correct and ready to implement. Never accumulate `@draft` tags silently — call them out in the report so the user knows what needs sign-off.

### Two-layer step model

Steps live at one of two levels. Keep them separate — do not mix levels within a scenario.

**Layer 1 — Interactions**: single primitive actions from the project's vocabulary (see below). Used in feature files that document a task directly.

**Layer 2 — Tasks**: named compositions of interactions representing a meaningful user action. Task steps appear as `Given` preconditions in higher-level feature files. Their implementations call interaction-layer steps.

```gherkin
# Layer 1 feature — documents "add to cart" in primitives
Scenario: Add a product to the cart
  Given I navigate to /products/widget
  When I click the Add to Cart button
  Then I should see "1 item in cart"

# Layer 2 feature — references "add to cart" as a precondition
Scenario: Complete a purchase
  Given I have added "Widget" to my cart
  When I click the Checkout button
  Then I should be on /order-confirmation
```

**Background vs. task step — decision rule:**
- Same interaction sequence appears as a precondition in **2+ scenarios across different feature files** → define a task step
- Sequence only repeats within one feature file → use `Background:`
- Never create a task step solely to avoid writing primitives once — only to eliminate duplication across features

**Task step naming:**
- Use state/past-tense language: `I have {done X}`, `a {thing} exists`, `{X} has been set up`
- Interaction steps use present-action language: `I click`, `I fill in`, `I navigate`
- The tense difference makes the layer immediately visible when reading a scenario

**Proposing new steps:**
- Interaction steps must come from the project's established primitive vocabulary. If the project's domain is not covered by the reference vocabularies below, establish a new primitive family before writing any feature files — document it in `GAPS.md` and get confirmation before use. Do not invent one-off interaction steps inside scenarios.
- Task steps only when the cross-feature duplication condition above is met; note which feature files they consolidate
- Do not propose a task step that wraps a single interaction — that is just renaming a primitive
- Any scenario using an unimplemented or unconfirmed step gets tagged `@draft`

### Primitive vocabulary (Layer 1)

The primitive vocabulary is domain-dependent. This skill ships two reference vocabularies — **browser** and **CLI**. Use the one that fits the project's interface; a single project may use both (e.g. a CLI tool with a web UI). When the project's domain fits neither (e.g. a mobile app, a message-queue consumer, an API-only service), establish a new primitive family in `GAPS.md` and get confirmation before writing any feature files.

Parameters use `{curly_braces}`.

**Browser** — locators use visible text or label; never CSS selectors, XPath, or element IDs.

| Step | Category | Notes |
|---|---|---|
| `I navigate to {url}` | Navigation | Absolute or root-relative URL |
| `I click the {text} link` | Interaction | Matches visible link text |
| `I click the {text} button` | Interaction | Matches button label |
| `I click {text}` | Interaction | Any clickable element; use typed variants above when unambiguous |
| `I fill in {field} with {value}` | Input | `{field}` is the input label or placeholder |
| `I select {option} from {field}` | Input | For `<select>` elements |
| `I check {field}` | Input | Checkbox by label |
| `I uncheck {field}` | Input | Checkbox by label |
| `I submit the form` | Input | Submits the active form |
| `I should see {text}` | Assertion | Visible text anywhere on the page |
| `I should not see {text}` | Assertion | |
| `I should be on {path}` | Assertion | URL path match |
| `the {field} field should contain {value}` | Assertion | |
| `the {field} field should be empty` | Assertion | |
| `the {text} button should be disabled` | Assertion | |
| `the {text} button should be enabled` | Assertion | |
| `I should see an error {text}` | Assertion | For inline validation messages |

**CLI** — commands are subcommand-and-flags only; path arguments go in a separate `at path "{path}"` clause. Values go in step text, not fixture names — step definitions stay generic and parameterised.

When a scenario needs to reference the per-test temp directory inside a command string or a path argument, write the literal token `{tmp}` in the feature file — e.g. `When I run command "init {tmp}/workspace"`. The step definition is responsible for substituting `{tmp}` with the actual `tmp_path` (or framework equivalent) at runtime. This keeps feature files portable across environments and free of absolute paths, while letting step text remain self-describing. Bare relative paths in non-command step text (e.g. `the directory "workspace/raw"`) are resolved against `tmp_path` directly by the step definition — no `{tmp}` prefix needed there.

| Step | Category | Notes |
|---|---|---|
| `I run command "{command}"` | Invocation | Subcommand and flags only, e.g. `"init"`, `"collect --all"` |
| `I run command "{command}" at path "{path}"` | Invocation | As above, with explicit working directory |
| `the last command should succeed` | Assertion | Exit code 0 |
| `the last command should fail` | Assertion | Non-zero exit code |
| `the last command should exit with code {code}` | Assertion | Specific exit code |
| `the last command output should contain "{text}"` | Assertion | Match against stdout/stderr |
| `the file "{path}" exists` | State | Pre-state: file present |
| `the file "{path}" does not exist` | State | Pre-state: file absent |
| `the directory "{path}" exists` | State | Pre-state: directory present |
| `the directory "{path}" does not exist` | State | Pre-state: directory absent |
| `the file "{path}" should exist` | Assertion | Post-state: file was created |
| `the file "{path}" should not exist` | Assertion | Post-state: file was not created |
| `the directory "{path}" should exist` | Assertion | Post-state: directory was created |
| `the directory "{path}" should not exist` | Assertion | Post-state: directory was not created |
| `the file "{path}" should contain "{text}"` | Assertion | File content match |

## Shared: progress tracking

Each feature file carries a `**Status**:` line below its title. Statuses flow in one direction — do not move backwards without a note explaining why.

| Status | Meaning |
|---|---|
| `draft` | Spec written; needs review before implementation begins |
| `ready` | Spec approved; awaiting implementation |
| `in progress` | Implementation underway; scenarios not yet passing |
| `passing` | All acceptance scenarios green |
| `failing` | Scenarios were passing; now failing (regression) |
| `deferred` | Intentionally postponed; not counted in progress |

**INDEX.md** maintains a features table with a Status column — the single place to see all features and their status at a glance. `deferred` features are excluded from progress counts.

**Updating statuses:**
- `create` and `infer` modes: all new features start at `draft`
- `update` mode: when code evidence confirms a feature is implemented and tests are present, propose advancing to `in progress` or `passing`; when referenced code disappears, flag as `failing` and prompt the user
- Status changes outside `update` mode are manual — the user edits the feature file and INDEX.md directly
- After any status change, recalculate the INDEX.md progress counts

## Shared: templates

All templates are in `references/templates/`. Read each one just-in-time — only when you're about to generate that file. Do not load all templates upfront.

| Template | Used by |
|---|---|
| `index.md.template` | all modes |
| `architecture.md.template` | all modes |
| `data-model.md.template` | all modes — when the project has persistent or structured data |
| `design-decisions.md.template` | all modes |
| `feature.md.template` | all modes — human-readable context |
| `feature.feature.template` | all modes — executable Gherkin |
| `gaps.md.template` | all modes |
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

#### 0. Cold-start interview (skip if context already exists)

If the skill is invoked with no prior conversation — empty chat, blank project directory, or a bare `/spec create` with no description — do not attempt to synthesise; there is nothing to synthesise yet. Instead, conduct a short structured interview.

Ask questions **one at a time**, in this order. Use earlier answers to skip questions that are already answered. Stop as soon as all must-have questions are resolved — do not ask nice-to-have questions if the picture is already clear enough to draft.

**Must-have (always ask if unanswered):**

1. *"What does it do, and who is it for?"* — the one-sentence pitch
2. *"Who are the different types of users?"* — distinct actors; may be implicit in the answer to 1
3. *"What are the 3–5 core things users need to be able to do?"* — jobs to be done
4. *"What's essential for the first version, and what can wait?"* — MVP boundary

**Strongly useful (ask if still unclear after the above):**

5. *"What is explicitly out of scope?"* — prevents the feature list from expanding unboundedly
6. *"What platform or interface?"* — web app, mobile, CLI, API, or combination

**Nice to have (ask only if relevant and not yet answered):**

7. *"Are there existing systems this needs to integrate with or replace?"*
8. *"Any hard constraints — compliance, performance, specific tech stack?"*

Keep questions short and conversational. Do not present them as a numbered list to the user — ask naturally, one at a time, and acknowledge each answer before asking the next. Once the must-haves are covered, proceed to step 1.

#### 1. Elicitation summary

Synthesise from the conversation (or interview answers from step 0):

- **Product/feature**: what it does and for whom (one sentence)
- **Actors**: who uses the system and in what roles
- **Core goals**: outcomes actors are trying to achieve (3–6 items)
- **Constraints**: technical, legal, timeline, or product constraints explicitly mentioned
- **Non-functional requirements**: only what was stated
- **Domain vocabulary**: key terms and their definitions as used in the discussion
- **Scope signals**: anything explicitly said to be in or out of scope

Flag any category with insufficient signal — those become initial Open entries in `DESIGN_DECISIONS.md`.

Also identify from the conversation:
- **Design principles**: any "how we build" rules stated or implied — architectural patterns, coding philosophy, team norms
- **Constraints**: hard limits mentioned — technical, legal, operational, or organisational

If neither has been stated, ask before proceeding to feature enumeration. These shape how every feature is described and what belongs in Technical notes — they cannot be retrofitted cleanly once features are written.

**Stop. Let the user correct or extend the elicitation summary before proceeding.**

#### 2. Feature enumeration

Draft the full feature list — each with a one-line user-facing description, the actor, and an MVP / later-phase label. This is the complete map of the system, not a shortlist.

**Stop. Confirm the feature list before scaffolding or writing any feature files.**

#### 3. Scaffold

Create directory structure and stub files: `INDEX.md` (stub), `ARCHITECTURE.md` (stub — sections present, content TBD), `DESIGN_DECISIONS.md` (populate with decisions and open questions surfaced so far), `GAPS.md` (empty structure), and `features/` (empty).

If the project has entities, records, or structured data that will be persisted or shared across features, also create `DATA_MODEL.md` (stub). If it is not obvious from the conversation, ask: *"Does this project have a data model — entities or records that need defining?"*

**Stop. Confirm structure before populating.**

#### 4. First feature

Generate one feature file in full, with these adaptations:
- `Technical notes` → populate what's known; use `TBD: <question>` for undecided implementation details; each TBD should also appear in `DESIGN_DECISIONS.md` (Open)
- `Relevant principles / constraints` → identify which entries from `ARCHITECTURE.md` shape this feature's implementation; if ARCHITECTURE.md is not yet populated, note what principles apply based on the discussion so far
- `Notes on confirmation` → rename to `Notes on scope`; flag scenarios that are inferred from discussion (not explicitly stated), edge cases not discussed, or contingent on an open decision

**Stop. Get explicit feedback before applying the format to remaining features.**

#### 5. Remaining features → Finalise → Report

Generate remaining features. Complete `INDEX.md`. Populate `ARCHITECTURE.md` with the cross-cutting design that emerged from the discussion — key abstractions, module boundaries, and the structural choices that span multiple features. Populate `DESIGN_DECISIONS.md` with all choices and open questions from the session. Report: file tree, domain vocabulary established, count of open decisions, count of spec gaps, count of `@draft` scenarios needing step implementation, recommended next step.

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

Read input documents. Build a map of the codebase (directory listing, outline-mode reading — don't load full files speculatively). Identify major user-facing capabilities and the existing step vocabulary.

While reading, look for evidence of design principles and constraints in `CLAUDE.md`, `ARCHITECTURE.md`, `PLAN.md`, READMEs, or configuration. These may be explicit ("we use a layered architecture") or implicit (a consistent pattern across the codebase that reflects a deliberate choice).

Report: what you found, then the full feature list — each with a one-line user-facing description. Include all confirmed user-facing capabilities, not a shortlist. Include a brief section on principles and constraints identified — and explicitly flag if none were found, prompting the user to state them before features are written.

**Stop. Wait for the user to confirm the feature list and establish any missing principles / constraints.**

#### 2. Scaffold

Create directory structure and stub files: `INDEX.md` (begins with a plain-English product description, 1–2 sentences, no class names or file paths), `ARCHITECTURE.md` (stub), `DESIGN_DECISIONS.md` (stub), `GAPS.md`, and `features/` (empty).

If the codebase has models, schemas, migrations, or structured data types, also create `DATA_MODEL.md` (stub — populate in step 4 from what you've read).

**Stop. Confirm structure before populating.**

#### 3. First feature

Generate one feature file in full. Apply the confirmed-only rule strictly. Tag any scenario with `@draft` if it uses steps not yet in `step_definitions/`. In Technical notes, populate `Relevant principles / constraints` from `ARCHITECTURE.md` — which principles or constraints visibly shape how this feature is implemented.

**Stop. Get explicit feedback on the first feature before applying the format to the rest.**

#### 4. Remaining features → Finalise → Report

Generate remaining features. Complete `INDEX.md`. Populate `ARCHITECTURE.md` by synthesising from the codebase: key abstractions, module structure, system boundaries, and the major structural patterns observed. Populate `DESIGN_DECISIONS.md` with any structural choices that are visible in the code but whose rationale is not self-evident — note them as Decided entries with the evidence as context. Report: file tree, what's covered and what's in GAPS, count of `@draft` scenarios needing step implementation, patterns or inconsistencies noticed (flag, do not fix).

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

**Never silently delete.** Removed features get archived to `specs/archived/`, not deleted.

**Changes reviewed via git.** Apply changes directly to files. The user reviews via `git diff specs/` and commits, amends, or reverts as they choose.

### Change detection (in preference order)

1. **Git-based**: `git log -- specs/ | head -1` to find the last commit touching `specs/`, then diff from there to `HEAD`
2. **Fallback**: compare file modification times between `specs/` and source directories

Report the detection method used. This appears in `SYNC_REPORT.md`.

### Categorisation

For every spec feature, assign one of:
- **Unchanged** — referenced code has not changed
- **Drift candidate** — code changed in a way that may affect behaviour
- **Refactor only** — code changed but behaviour appears preserved
- **Deprecated candidate** — referenced code no longer exists

For new or significantly-changed code with no matching feature: **Uncovered**

For `GAPS.md` entries: **Resolved**, **Still open**, or **Obsolete**

For `@draft` scenarios: **Ready** (steps now exist — remove tag), **Still pending** (steps not yet implemented — leave tag), or **Obsolete** (scenario removed)

**Stop. Report the categorisation summary (numbers only). Confirm scope before applying changes.**

### Applying changes

In order:
- **Refactor-only**: update technical notes (paths, type names) without touching scenarios
- **Drift candidates**: update unambiguous changes; prompt the user on ambiguous ones
- **Uncovered**: create feature files using `references/templates/feature.md.template`; apply confirmed-only rule
- **Deprecated**: move to `specs/archived/<feature-slug>.md` with deprecation header (date, last commit, reason if known — prompt if unknown)
- **Resolved gaps**: move content into the relevant spec file; add a brief "resolved" note in `GAPS.md`
- **Ready `@draft` scenarios**: remove the `@draft` tag
- **Obsolete entries**: remove with a one-line note in a history section if one exists

### Update cross-cutting files

- `INDEX.md`: add candidate features if new uncovered areas suggest them; recalculate progress counts
- `ARCHITECTURE.md`: update when structural changes are detected — new modules, changed boundaries, revised abstractions; do not touch if the changes are behaviour-only
- `DATA_MODEL.md`: update when entities are added, removed, or their fields/types change; if `DATA_MODEL.md` doesn't exist but the codebase now has meaningful persistent data, propose creating it
- `DESIGN_DECISIONS.md`: append new entries for structural choices made since the last sync; never overwrite existing entries
- `GAPS.md`: open and newly-discovered gaps only

### Finalise

Write `specs/SYNC_REPORT.md` using `references/templates/sync-report.md.template`.

Report: total files changed, clarifications requested and resolved, items deferred, pointer to `SYNC_REPORT.md`, suggestion to review via `git diff specs/`.

### When to prompt the user

Bundle clarification questions when possible. Ask (don't guess) when:
- A behaviour change could be intentional contract change or accidental regression
- A feature appears removed but might have been renamed
- Multiple plausible mappings exist between new code and existing features

---

## Override flags (all modes)

- **"Generate all features in one pass"** — after confirming the feature list, generate all features without stopping between them; still stop after the first feature for format review
- **"Include inferred behaviour, tag inline"** — (infer/update) switch to Confirmed/Inferred/Gap inline tagging instead of separate GAPS.md
- **"Skip step definition verification"** — write idiomatic Gherkin without checking against the library; still record proposed steps
