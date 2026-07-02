---
description: Quick sanity check on staged or recent changes
allowed-tools: Bash(git diff *), Bash(git log *), Read, Task
---

Spawn a Task agent (subagent_type: general-purpose) for a quick sanity check. Fresh eyes, no ownership bias.

Pass the following prompt to the agent:

---

Quick sanity check on the staged changes. Run `git diff --staged` (or `git diff HEAD~1` if nothing staged).

Three things:

1. **What and why?**
   - What does this change do? (1 sentence)
   - Why? Infer the intent from the code (1 sentence)

2. **Anything obviously wrong?**
   - Typos, copy-paste errors
   - Forgotten debug code (print statements, TODOs that should be removed)
   - Obvious logic errors
   - Missing imports or unused variables
   - Inconsistent naming

3. **Is this worth committing?**
   - Does it solve a real problem or add value?
   - Or is it just noise/churn?

Don't overthink it. Keep response short.
