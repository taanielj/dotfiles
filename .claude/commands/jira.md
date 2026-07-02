---
description: Jira helper - view, create, update, and transition tickets via the jira CLI
allowed-tools: Bash(jira *), Bash(command -v jira), AskUserQuestion, Read
argument-hint: "<view|create|comment|transition> [ticket-id] [args]"
---

Generic helper around the [`jira` CLI](https://github.com/ankitpokhrel/jira-cli). Works with any Jira instance once the CLI is configured.

## Prerequisites

- `jira` CLI installed and authenticated (`jira init`). If `command -v jira` fails, tell the user to install and configure it, then stop.
- Optional: `$JIRA_BASE_URL` for building browser links (e.g. `https://your-org.atlassian.net`). If unset, skip link generation.

## Sub-commands

Parse `$ARGUMENTS`. First token selects the action:

- **view `<TICKET>`** - `jira issue view <TICKET> --plain` (plain text, no jq needed). Summarize status, assignee, and the description's intent.
- **create** - gather summary, type, and description (AskUserQuestion for anything missing), then `jira issue create`. Do NOT invent field values; ask.
- **comment `<TICKET>`** - add a comment with `jira issue comment add <TICKET>`.
- **transition `<TICKET>`** - list available transitions with `jira issue move`, confirm the target state, then move it.

## Rules

- Never fabricate ticket contents or field values - read them from the CLI or ask the user.
- Never transition or edit a ticket without confirming the target first.
- Prefer `--plain` output over JSON unless you specifically need to parse fields.
- If `$JIRA_BASE_URL` is set, offer a browser link `$JIRA_BASE_URL/browse/<TICKET>` after actions.
