---
name: commit-msg
description: Generate a git commit message from the current staged/unstaged changes and save it to .git/NEXT_COMMITMSG to pre-populate the next manual commit. Use when the user types /commit-msg or asks you to generate a commit message, draft a commit, or write a commit suggestion.
argument-hint: [scope]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

# Commit Message Generator

Generate a focused commit message from current git state and write it to `.git/NEXT_COMMITMSG` so it pre-populates the user's next manual commit. Never commit — only write the suggestion.

## Steps

1. **Gather git state** — run all three in parallel:
   - `git status` (to see staged vs unstaged files)
   - `git diff HEAD` (full diff of staged and unstaged changes)
   - `git log --oneline -10` (recent history to match tone and style)

   **If any files are staged, the message must describe only the staged changes.** Use `git diff --cached` as the source of truth and ignore unstaged changes when drafting. Only fall back to the full working tree (`git diff HEAD`) when nothing is staged.

2. **Draft the commit message** — follow these rules:
   - First line: imperative mood, ≤72 chars, no trailing period, no scope prefix unless an argument was passed to the skill
   - If an argument was passed (e.g. `/commit-msg auth`), prefix the subject with `scope: ` (e.g. `auth: add JWT refresh logic`)
   - Optional body: separate from subject with a blank line; explain *why*, not *what*; wrap at 72 chars
   - No `Co-Authored-By` or other trailers — the user adds those manually if wanted
   - Match the capitalization and style of recent commits in the log

3. **Write the message to `.git/NEXT_COMMITMSG`** — do this without prompting.
   ```
   <subject line>

   <optional body>
   ```

4. **Confirm** — show the proposed message in a code block and tell the user it's been written; they can commit via `git commit`, which reads it into the buffer.

## Notes

- If there are no staged or unstaged changes, report that immediately and stop.
- If the diff is large (many files or many hunks), summarize the intent rather than listing every file — keep the subject line crisp.
- Never add `Co-Authored-By: Claude` or any AI attribution trailers unless the user explicitly asks.
- This skill never commits — it only writes the suggestion to `.git/NEXT_COMMITMSG`.
