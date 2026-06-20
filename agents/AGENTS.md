# Working with Nick

## Development philosophy

### Test-driven development
Write failing tests before implementing. Tests are not just validation — they are a design tool:
- Use tests to reason about architecture: what should interfaces look like, what's the domain model, what are the ergonomics for a caller of this code?
- Write the test file first, present it for review, then implement to make it pass.
- Tests as documentation: a well-written test suite explains how the system works.

If I ask you to "add tests" after the fact, that means you missed TDD — adjust going forward.

When a test fails mid-task, stop and determine which situation applies:
- **Accidental regression** — something broke that shouldn't have; fix the code, not the test.
- **Intentional behaviour change** — the test is now wrong because the design changed; update the test and explicitly flag the change to the user.

Never silence a failing test or adjust it to pass without identifying which case applies first.

Treat test coverage as a weak signal, not a guarantee. Coverage tells you a line was executed — not that its behaviour was verified. When reviewing or writing tests, check that assertions would actually catch a bug, not just that the code path is exercised.

For projects where test quality matters, suggest mutation testing (Stryker for JS/TS, mutmut for Python) as a periodic check rather than a CI gate — it's too slow to run continuously but effective at finding tests that execute without validating.

### README-driven development
Before writing code for a new project or feature, I sometimes write the README first — describing how the thing will be used, what it does, and what the interface looks like. Treat the README as the design document and the source of truth for what to build.

When a README exists before implementation:
- Read it before proposing any architecture or writing any code.
- Use it to resolve ambiguity about intended behaviour — what the README describes is what we're building.
- Flag any gaps or contradictions between the README and the code as you find them.
- Keep the README in sync as the implementation evolves; if the README says one thing and the code does another, that's a bug in the docs.

This pairs naturally with TDD: README describes the intent → tests encode the behaviour → code makes them pass.

### Deterministic before AI
Prefer rule-based, algorithmic solutions first. Only reach for LLMs when a deterministic approach is genuinely insufficient. LLMs introduce latency, cost, and non-determinism — those tradeoffs need to be justified by real ambiguity in the problem.

Design pattern: deterministic fast path → LLM fallback for edge cases or genuine ambiguity.

### Layer-by-layer development
Build in layers: core library → CLI → API → frontend. Each layer depends only on the one below it. Logic lives in the library; the web/API layer is thin. Don't bleed concerns across layers.

Where tooling supports it, encode layer boundaries as enforced rules rather than conventions — e.g. `dependency-cruiser` for JS/TS projects. Error messages should describe the architectural intent, not just the violation, so future agents and developers understand why the boundary exists. If no enforcement tool is in place for a project with meaningful layering, suggest adding one.

### Simplicity
- Prefer simple, direct naming. If a name feels redundant, it probably is.
- Don't add abstractions, features, or error handling beyond what the task requires.
- Three similar lines is better than a premature abstraction.

When modifying a file that is heavily imported or depended on, flag it — high coupling means changes carry more risk and warrant closer review. Don't attempt to restructure coupling without being asked; what looks like over-coupling often has legitimate architectural reasons that aren't visible from the import graph alone.

### The Rails Way
I have extensive experience with the Ruby on Rails framework and like the architecture,
and often use it as an ideal for design principles (convention over configuration,
ActiveModel), having a functional REPL I can use to interact with the software (hence
the layered approach).

---

## How I work

### Explanation before architecture
Before committing to an architectural decision or an unfamiliar mechanism, give a brief explanation. Once I signal I understand, move immediately to implementation — don't over-explain.

### Decision points
When there are genuinely valid trade-offs, present 2–3 options with the key difference, then recommend one and say why. Don't just ask me to decide blind.

### Verbosity
Silent on routine changes — I can read the code. Flag anything non-obvious: a surprising constraint, a judgment call, a trade-off you made without asking. One sentence is usually enough.

### Commit messages
After each logical change, write a short suggested commit message to `.git/NEXT_COMMITMSG` at the repo root (overwriting any prior suggestion). My `commit.template` is configured globally to point at that file, so the message pre-populates when I commit via tig or `git commit`. Don't commit — just write the file and mention briefly that you've updated it.

**Always prefix the suggestion with a literal first line `GENERATED MESSAGE`, with the actual message starting on the next line (no blank line between them).** I delete that sentinel line to confirm I want to use the suggestion. If I leave it in place, git's "you did not edit the message" check aborts the commit — which is the intended safety net.

### API changes
After any change to an API endpoint, show httpie examples for the affected routes.

### Documentation
After each major feature, update the relevant docs — typically PLAN.md, ARCHITECTURE.md, and README.md. Treat docs as a deliverable, not a chore.

### New project setup
When starting a new project, or when working in a codebase that appears small or early-stage, proactively suggest setting up code quality tooling if it isn't already present — don't wait to be asked. This includes linting, formatting, type checking, and static analysis:
- **Python:** ruff (lint + format), mypy (type checking), bandit or similar (SAST)
- **JS/TS:** ESLint, Prettier, tsc strict mode
- Wire these into a Makefile or equivalent so `make lint`, `make typecheck`, `make test` all work from day one.
- CI should run all of the above.

When configuring linters, explicitly set thresholds for AI-prone failure modes — these are rarely in default presets:
- Maximum function arguments (e.g. 4–5)
- Maximum function length (e.g. 30–50 lines)
- Maximum file length (e.g. 300–500 lines)
- Cyclomatic complexity ceiling (e.g. 10)

If a linter rule fires, fix the underlying issue. Don't suppress warnings or raise thresholds without a documented reason.

Also suggest mutation testing as a periodic quality check — Stryker for JS/TS, mutmut for Python. Wire it into the Makefile (e.g. `make mutation`) but not CI, as it's too slow for every commit.

### Single source of truth for version
Project version lives in exactly one place. For Python, that's `pyproject.toml` — do not also declare `__version__` in `__init__.py`, do not hardcode it in CLI `--version` output, do not duplicate it in docs that change with releases. If runtime code needs the version, read it from the package metadata (`importlib.metadata.version("pkgname")`). Same principle in other ecosystems: `package.json` for JS, `Cargo.toml` for Rust, etc. — never two places that can drift.

---

## Hard rules

**Never commit without being asked.** Stage changes, but do not commit. Wait for an explicit instruction to commit.

**TDD by default.** Write failing tests first. If you're about to implement something non-trivial without a test, stop and write the test first.

**No scope creep.** Only implement what was asked. Don't refactor surrounding code, add logging, introduce new patterns, or expand scope without being asked.

**Deterministic first.** Don't reach for an LLM solution when a rule-based one will do.

**No secrets in code.** Always read credentials and API keys from environment variables. Never hardcode them.

**Validate at boundaries only.** Validate input at API/CLI entry points. Trust internal code and framework guarantees — don't add defensive checks for scenarios that can't happen.
