---
name: commit-msg
description: Generate a git commit message from the current staged/unstaged changes and prompt to either commit immediately or save to .git/NEXT_COMMITMSG. Use when the user types /commit-msg or asks you to generate a commit message, draft a commit, or write a commit suggestion.
argument-hint: [scope]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

# Commit Message Generator

Generate a focused commit message from current git state, then let the user decide whether to commit immediately or stage the suggestion for their next manual commit.

## Steps

1. **Gather git state** — run all three in parallel:
   - `git status` (to see staged vs unstaged files)
   - `git diff HEAD` (full diff of staged and unstaged changes)
   - `git log --oneline -10` (recent history to match tone and style)

2. **Draft the commit message** — follow these rules:
   - First line: imperative mood, ≤72 chars, no trailing period, no scope prefix unless an argument was passed to the skill
   - If an argument was passed (e.g. `/commit-msg auth`), prefix the subject with `scope: ` (e.g. `auth: add JWT refresh logic`)
   - Optional body: separate from subject with a blank line; explain *why*, not *what*; wrap at 72 chars
   - No `Co-Authored-By` or other trailers — the user adds those manually if wanted
   - Match the capitalization and style of recent commits in the log

3. **Present the message** — show the full proposed commit message in a code block so the user can read it clearly.

4. **Ask the user** what to do next — offer exactly two options:
   - **Commit now**: stage any unstaged changes with `git add -u`, then commit with the message
   - **Save to NEXT_COMMITMSG**: write the message to `.git/NEXT_COMMITMSG` in the sentinel format (see below) so it pre-populates the next manual commit

5. **Execute** the chosen path:

   **Commit now path:**
   ```bash
   git add -u
   git commit -m "$(cat <<'EOF'
   <subject line>

   <optional body>
   EOF
   )"
   ```
   Then confirm success with `git log --oneline -1`.

   **Save to NEXT_COMMITMSG path:**
   Write the file with this exact format — the sentinel on line 1, the message starting on line 2 with no blank line between them:
   ```
   GENERATED MESSAGE
   <subject line>

   <optional body>
   ```
   The sentinel `GENERATED MESSAGE` is a safety net: git aborts the commit if the user does not delete that line, preventing accidental use of an unreviewed suggestion.

   Confirm by telling the user the message has been saved and they can commit via `git commit` (which will use the template).

## Notes

- If there are no staged or unstaged changes, report that immediately and stop.
- If the diff is large (many files or many hunks), summarize the intent rather than listing every file — keep the subject line crisp.
- Never add `Co-Authored-By: Claude` or any AI attribution trailers unless the user explicitly asks.
- This skill never commits without the user choosing the "Commit now" path explicitly in step 4.
