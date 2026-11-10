#!/bin/sh
# Sets the $tab sidebar token to each workspace's active tab name, and clears it
# while that tab still has its automatic number. Skips workspaces whose token
# already has that value.
herdr=${HERDR_BIN_PATH:-herdr}

labels=$("$herdr" tab list | jq -c '.result.tabs | map({key: .tab_id, value: .label}) | from_entries')

"$herdr" workspace list | jq -r --argjson labels "$labels" '
  .result.workspaces[]
  | ($labels[.active_tab_id] // "") as $label
  | (if $label | test("^[0-9]+$") then "" else $label end) as $want
  | select($want != (.tokens.tab // ""))
  | [.workspace_id, $want] | @tsv' |
    while IFS="$(printf '\t')" read -r workspace tab; do
        # An empty value clears the token.
        "$herdr" workspace report-metadata "$workspace" --source user:active-tab --token "tab=$tab" >/dev/null
    done
