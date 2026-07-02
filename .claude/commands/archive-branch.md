---
name: archive-branch
description: Create an orphan git branch preserving a deleted path before it disappears from history
user-invocable: true
argument-hint: "<path> [<pre-deletion-commit>]"
---

Create an orphan branch `archive/<path-basename>` containing only the files at `<path>` as they existed at `<pre-deletion-commit>` (default: `HEAD~1`). Uses a temporary worktree — the main working tree is never touched.

## Arguments

Parse `$ARGUMENTS`:
- First token: path to archive (e.g. `etl/`, `legacy/`)
- Second token (optional): commit where the path still exists. Default: `HEAD~1`

## Steps

Run sequentially — each must succeed before the next:

1. Derive names:
   ```
   archive_branch="archive/$(basename ${path%/})"
   worktree_path="/tmp/$archive_branch"
   ```

2. If the archive branch already exists, abort and ask the user whether to delete and recreate it.

3. Create orphan branch in a temp worktree (main working tree stays untouched):
   ```
   git worktree add --orphan -b "$archive_branch" "$worktree_path"
   ```

4. Restore only the target path from the pre-deletion commit into the worktree:
   ```
   git -C "$worktree_path" checkout <pre-deletion-commit> -- <path>
   ```

5. Commit:
   ```
   git -C "$worktree_path" add <path>
   git -C "$worktree_path" commit -m "archive: <path> before deletion"
   ```

6. Clean up the worktree:
   ```
   git worktree remove "$worktree_path"
   ```

7. Confirm: `git log --oneline "$archive_branch"` and report the branch name and commit to the user.

## Notes

- Do NOT push the archive branch unless asked.
- If `<pre-deletion-commit>` is a relative ref like `HEAD~1` or `abc123^`, pass it as-is to git.
