---
description: Create a git branch from ticket name with conventional prefix
allowed-tools: Bash(git checkout *), Bash(git branch *), Bash(git status), AskUserQuestion
---

Create and checkout a new git branch.

## Args

- **$0** (required): Ticket name (e.g., `PROJ-1234`)
- **$1** (optional): Branch description in plain words (e.g., `fix login bug`)

Examples:
- `/branch PROJ-1234 fix login timeout` - asks for prefix, uses description
- `/branch PROJ-1234` - asks for both prefix and description

## Process

1. Parse ticket name from `$0` (first argument). If missing, use AskUserQuestion to ask:
   - "What's the ticket name?" with a free-text option (e.g., `PROJ-1234`)
2. If `$1` is not provided (no description), use AskUserQuestion to ask:
   - "What's a short description for this branch?" with a free-text option
3. Use AskUserQuestion to ask for the branch type:
   - Options: `fix` (Bug fix), `feat` (New feature), `chore` (Maintenance/cleanup)
4. Slugify the description: lowercase, replace spaces with hyphens, strip non-alphanumeric characters (keep hyphens)
5. Construct branch name: `{prefix}/{TICKET}/{slugified-description}`
6. Run `git checkout -b {branch-name}`
7. Confirm the created branch to the user
