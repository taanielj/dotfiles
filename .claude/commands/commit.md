---
description: Automatically review staged files and create a commit with proper messaging
allowed-tools: Bash(git status), Bash(git diff *), Bash(git commit *), Bash(git log *), Bash(git add *)
---

Do NOT use `git -C <path>` if you are already in the repo directory.

Review staged changes and create a commit quickly without verbose tracking.

1. Run `git diff --staged --stat` first to see all changed files, then run `git diff --staged` to see the full diff. Do NOT use `git -C <path>` if you are already in the repo directory.
2. If diff output is too long, exclude generated files (e.g., `generated/` dirs, lockfiles, vendored code). If still too large after that, use the --stat file list to read each remaining file individually rather than skipping them
3. Check and run pre-commit hooks first with `git commit --dry-run` or attempt commit
4. If hooks fail but modify files (like formatting), stage the changes with `git add .`
5. **Default: ONE LINE COMMIT.** Only add a body if you answer YES to: "Does this change architecture or runtime behavior in a way the title cannot convey?" Comment changes, dependency bumps, reformatting, config tweaks, regenerated files - the answer is always NO.
   - Compound actions can be chained with "and" if the title stays under 50 chars.
   - File count and diff size are irrelevant. One logical goal = one line.
   - Examples of one-line commits:
     ```
     Tidy dep comments and refresh lockfile
     Bump http client to 2.4.0
     Regenerate API client from schema
     Rename user_id to owner_id
     Fix null check in retry loop
     ```
   - Complex (title + body) is rare. The body describes intent, not content - never read the diff back to the reader. Example:
     ```
     Add batch mode to the export pipeline

     Lets the exporter process records in configurable chunks instead of
     one at a time, cutting memory use on large jobs. Wires the chunk size
     through config, the CLI flag, and the worker loop.
     ```
6. Commit with the message(s) - do NOT add any AI attribution, Claude mentions, or co-authored tags
   If pre-commit hooks fail and modify files, stage those changes before committing.
   Keep commit messages natural and descriptive. Never use em dashes (—), use regular dashes (-) instead.

**⚠️ CRITICAL SAFETY WARNING:**
NEVER use `git commit --amend` if the previous commit failed completely. When pre-commit hooks fail, no new commit is created - HEAD still points to the previous commit. Using `--amend` would modify that previous commit (potentially on main branch), which is extremely dangerous. Always verify with `git status` that you're ahead of the base branch before amending.

Do NOT use `git -C <path>` if you are already in the repo directory.
