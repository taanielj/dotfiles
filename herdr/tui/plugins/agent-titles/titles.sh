#!/bin/sh
# Sets the $title sidebar token to the session title on agent panes that share
# their tab with another agent, and clears it everywhere else. Skips panes whose
# token already has that value.
herdr=${HERDR_BIN_PATH:-herdr}

"$herdr" pane list | jq -r '
  .result.panes
  | (map(select(.agent)) | group_by(.tab_id)
     | map({key: .[0].tab_id, value: length}) | from_entries) as $agents
  | .[]
  | (if .agent and $agents[.tab_id] > 1 then .terminal_title_stripped // "" else "" end) as $want
  | select($want != (.tokens.title // ""))
  | [.pane_id, $want] | @tsv' |
    while IFS="$(printf '\t')" read -r pane title; do
        # An empty value clears the token.
        "$herdr" pane report-metadata "$pane" --source user:agent-titles --token "title=$title" >/dev/null
    done
