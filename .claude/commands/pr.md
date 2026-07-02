---
description: Create a pull request comparing current branch to main/master
allowed-tools: Bash(git status), Bash(git diff *), Bash(git log *), Bash(gh pr *), Bash(find *), Bash(*pbcopy), Read, Glob, AskUserQuestion
---

Create a pull request quickly without verbose tracking.

## Process

1. Compare current branch to main/master using `git diff main...HEAD` or `git diff master...HEAD`
2. Check for existing PRs for this branch using `gh pr list --head $(git branch --show-current)`
3. **Find the PR template** - this MUST be case-insensitive:
   ```sh
   find .github/ -iname "*pull_request*" 2>/dev/null
   find . -maxdepth 1 -iname "*pull_request*" 2>/dev/null
   ```
   Read whatever is found. If nothing is found, fetch 2-3 of the current user's recently merged PRs (`gh pr list --author @me --state merged --limit 3`) and read their descriptions to match style.
4. Parse branch name to infer type (feature/fix/chore) and ticket ID (e.g., `fix/PROJ-1580/...` -> PROJ-1580)
5. If a ticket ID is detected and `$JIRA_BASE_URL` is set, generate a ticket link `$JIRA_BASE_URL/browse/{TICKET-ID}` and include it in the PR description. Skip if no base URL is configured.
6. Generate title in format: `Feature[TICKET-ID]: <description>` (or Fix/Chore as appropriate). Omit the `[TICKET-ID]` bracket if no ticket was detected.
7. **Fill the template properly** - every section should get real content based on the diff:
   - If a template section is applicable, fill it with actual information from the diff
   - If a section is not applicable, delete it (don't leave placeholder text)
   - If something important doesn't fit an existing section, add it where it makes sense
   - Tick relevant checkboxes, untick irrelevant ones
8. If PR already exists, update description with `gh pr edit`. If no PR exists, create with `gh pr create`. Do NOT add any AI attribution or Claude mentions.
9. AskUserQuestion with the PR URL - "Copy to clipboard" / "Open in browser" (skip if already offered this URL in the current session)

## The "Why"

You can infer WHAT changed from the diff. You CANNOT reliably infer WHY. Do not guess.

To get the "why", in priority order:
1. Check the linked ticket if one is detected and you have a way to read it
2. Otherwise AskUserQuestion: "What's the motivation for this change?"
3. Only skip asking if the "why" is truly self-evident from the diff (e.g., fixing a typo)

## Style

- Keep descriptions factual and technical, avoid marketing language ("enables", "functionality", etc.)
- Do NOT make assumptions about what's "standard" or "typical"
- Focus on WHAT was done and WHY - the "why" comes from the ticket or the user, not from inference
- Be concise, apply DRY principle to language
- Group similar changes logically to reduce repetition
- Never use em dashes, use regular dashes (-) instead
- For each change category, judge whether details are worth reading inline or are secondary:
  - If a category needs a high-level summary, put that as visible text
  - Put bullet-point details inside a collapsible `<details><summary>...</summary>` block
  - Skip the `<details>` wrapper when the bullets ARE the high-level summary

## Examples

Bad: "Add comprehensive data quality monitoring framework"
Good: "Add not-null and unique checks to the accounts table"

Bad: "Implement robust incremental loading strategy"
Good: "Switch the sync job to delete+insert for dedup"

Bad: "Create scalable regional filtering solution"
Good: "Fix filter to handle cross-region ID mapping"

## Pro-tip

If diff output is too long, exclude generated files from analysis. Examples: files in `generated/` directories, lockfiles, vendored dependencies.
