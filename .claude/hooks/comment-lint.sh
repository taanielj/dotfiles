#!/bin/bash
# Detect explanatory comments in code edits

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')

# Handle Edit and Write
if [ "$tool_name" = "Edit" ]; then
  content=$(echo "$input" | jq -r '.tool_input.new_string // empty')
elif [ "$tool_name" = "Write" ]; then
  content=$(echo "$input" | jq -r '.tool_input.content // empty')
else
  exit 0
fi

[ -z "$content" ] && exit 0

# Exclude markdown files
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
[[ "$file_path" == *.md ]] && exit 0

# Detect explanatory comment patterns:
# - "This/These/Here/We/The + verb" patterns
# - "Note:" "TODO:" with explanations
# - Long sentence-like comments (comment + 6+ words)
if echo "$content" | grep -qE '(//|#|--)\s+(This|These|Here|We|The|Note:|TODO:|FIXME:)\s+[a-z]' || \
   echo "$content" | grep -qE '(//|#|--)\s+[A-Z][a-z]+(\s+[a-z]+){5,}' || \
   echo "$content" | grep -qE '(//|#|--)\s+[A-Z]+-[0-9]+:' ; then
  cat <<EOF
{
  "decision": "block",
  "reason": "Style nudge (non-blocking): comment may be too explanatory - check codebase style."
}
EOF
  exit 2
fi

exit 0
