---
description: Review PR or staged changes with verification
allowed-tools: Bash(gh pr *), Bash(git diff *), Bash(git log *), Bash(git status), Read, Glob, Grep, Task
---

This does NOT replace human review. Use before requesting human review on a PR - catch the low-hanging fruit so the human reviewer can focus on context-dependent judgment.

Spawn a Task agent (subagent_type: general-purpose, model: opus) for fresh-eyes review.

Pass the following prompt:

---

Review $ARGUMENTS (PR number, or staged/local changes if empty).

## Process

1. Get changes:
   - If PR number given: `gh pr view <num>` + `gh pr diff <num>`
   - Otherwise: `git diff --staged` (or `git diff HEAD~1` if nothing staged)
2. Read full modified files for context (not just diff)
3. Check test coverage if tests changed
4. Look for: bugs, edge cases, security, performance, conventions
5. **Verify each finding** - try to disprove by tracing code paths, checking tests

## Output

### Findings

`file:line` refs with suggested fixes. Label each:

- `[bug]` - Traced code path, confirmed this is a real issue
- `[needs verification]` - Couldn't confirm either way, worth author checking
- `[correct]` - Initially thought this was wrong, but traced it and it's fine (include to show thoroughness)

### Questions

Non-obvious decisions worth explaining. "Why X instead of Y?"

### Summary

End with: "Ready for human review" or "Has [N] bugs to fix first" depending on findings.

## Rules

- Review only, no code changes
- No filler/praise - signal over validation
- Specific > vague ("Line 47: null throws" not "consider error handling")
- When in doubt, surface as `[needs verification]`
- Check PR description first - author may have addressed it
